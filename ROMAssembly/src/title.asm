.p816
.a8
.i16

.include "defines.inc"
.include "macros.inc"
.include "registers.inc"
.include "joypad.inc"

.export LoadTitleScreenAndWaitForInput
.export DoCharacterSelect

.import GetJoypadInputs
.import CopyBG3TileMapBufferToVRAM
.import CopyOamMirrorToOAM
.import DMA2VRAML : far

.segment "TITLEGRAPHICS"

TitleScreenSprites:    .incbin "graphics/title-screen-sprites.4bpp"  ; 16 KB
FontChr:               .incbin "graphics/font.2bpp"                  ; 4 KB
HandSprite:            .incbin "graphics/hand.4bpp"                  ; 128 bytes

.segment "BATTLEGRAPHICS"

BattleSprites:         .incbin "graphics/battle-sprites.4bpp"        ; 24 KB

.segment "CODE"

; Palettes and sprite data are stored with the code so they don't have to be long copies to CGRAM/OAM.
TitleScreenSpriteData: .incbin "data/title-screen-sprites.bin"
TitleScreenPalette:    .incbin "graphics/title-screen-palette.pal"
HandPalette:           .incbin "graphics/hand-palette.pal"
BattleSpritePalettes:  .incbin "graphics/battle-sprite-palettes.pal"

FontPalette:
	COLOR  0,  0,  0 ; normally 31/0/31, but this will be the actual background
	COLOR  0,  0, 31
	COLOR 31, 31, 31
	COLOR 16, 16, 16

;;;;;;;;;;;;;;;;
; Title Screen ;
;;;;;;;;;;;;;;;;

; This sets up the video for the title screen, loads the data,
; and puts it on the screen, then waits for the player to press
; A or start.
.proc LoadTitleScreenAndWaitForInput
	lda #GAME_MODE_OVERWORLD ; title screen is gonna use the overworld engine
	sta GameMode

	lda #$8f                ; force v-blanking
	sta INIDISP
	stz NMITIMEN            ; disable NMI

	jsr LoadTitleScreenSprites

	A8

	lda #$07                ; video mode 7
	sta BGMODE
	stz M7SEL               ; wrap tiles, no flipping
	;jsr SetMode7Matrix      ; set up Mode 7 transform parameters

	lda #$63                ; sprites are 16x16 and 32x32, sprite RAM is at $C000 (but word address $6000)
	sta OBJSEL

	lda #$11                ; enable sprites and BG1
	sta TM
	lda #$00                ; no background layers on subscreen
	sta TS
	lda #$00                ; set fixed color for subscreen
	sta CGWSEL
	lda #$81                ; enable color math for BG1, subtract mode
	sta CGADSUB
	lda #$ff                ; set fixed color to white
	sta COLDATA             ; this should fade the background entirely to black

	stz INIDISP             ; release forced blanking, set screen to zero brightness
	lda #$81
	sta NMITIMEN            ; enable NMI, turn on automatic joypad polling

	lda #$01
	pha                     ; save A because we're going to get interrupted
@FadeInLoop:
	wai                     ; wait one frame
	pla
	sta INIDISP             ; gradually increase brightness
	inc
	pha                     ; save A
	cmp #$10                ; until we've reached full brightness
	bne @FadeInLoop
	pla                     ; clear the stack

	A16
	lda #%111111111         ; this will count downward, and the upper 5 bits are the fixed color
	pha                     ; save A because we're going to get interrupted
@InputLoop:
	wai
	pla
	beq :+                  ; if we hit 0, we can't get any brighter
	dec
:
	pha
	lsr                     ; divide by 16
	lsr
	lsr
	lsr
	A8
	ora #$e0                ; all three color channels
	sta COLDATA             ; set the fixed color
	A16

	jsr GetJoypadInputs
	lda JoyTrigger1
	and #BUTTON_A | BUTTON_START
	beq @InputLoop
	pla                     ; clear the stack

	rts
.endproc

; The "Final Fantasy Superizer" on the title screen is sprites, so that
; they can be rendered over the overworld in Mode 7.  To simplify this,
; we can just bulk load the sprite configuration data from ROM.
.proc LoadTitleScreenSprites
	; First load the sprite graphics.
	A8
	XY16

	LONGCALL DMA2VRAML, BANK_TITLEGRAPHICS, TitleScreenSprites, $6000, $2800

	; Now load the palette.
	lda #$80
	sta CGADD                 ; start at CGRAM address $80
	ldx #$0000
@PaletteLoop:
	lda TitleScreenPalette, X ; get a byte of palette data
	sta CGDATA                ; write it to CGRAM
	inx
	cpx #$0020                ; length of palette data
	bne @PaletteLoop

	; Finally, copy the sprite data into OAM.
	A16
	ldx #$0000
@SpriteDataLoop:
	lda TitleScreenSpriteData, X  ; read
	sta OamMirror, X              ; write
	inx                           ; 2 bytes at a time
	inx
	cpx #$0220                    ; length of sprite data (same as OAM size)
	bne @SpriteDataLoop

	rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;
; Party Selection Screen ;
;;;;;;;;;;;;;;;;;;;;;;;;;;

.feature string_escapes
PartySelectString: .asciiz " PARTY  SELECT "
StatusString:      .asciiz " STATUS "
NameEntryString:   .asciiz " NAME  ENTRY "

ClassNameStrings:
	.byte "Fighter "
	.byte "Thief   "
	.byte "Blk Belt"
	.byte "Red Mage"
	.byte "Wht Mage"
	.byte "Blk Mage"
	.byte "Knight  "
	.byte "Ninja   "
	.byte "Master  "
	.byte "Red Wiz "
	.byte "Wht Wiz "
	.byte "Blk Wiz "

AMString:  .asciiz "A B C D E F G H I J K L M"
NZString:  .asciiz "N O P Q R S T U V W X Y Z"
amString:  .asciiz "a b c d e f g h i j k l m"
nzString:  .asciiz "n o p q r s t u v w x y z"
NumString: .asciiz "1 2 3 4 5 6 7 8 9 0 - + /"
SymString: .byte   "! ? . , % ; : ", $5f, " [ ] ' \"  ", $00 ; $5f is the ellipsis

CharacterNames  = $20 ; 32 bytes, 8 per character, fixed-length strings
ClassSelections = $1c ; 4 bytes, one per character
ClassPosition   = $1b
PartyPosition   = $1a
XPosition       = $19
YPosition       = $18
InputPosition   = $17

.proc DoCharacterSelect
	AXY8
	stz ClassPosition
	stz PartyPosition
	stz InputPosition
	lda #$20                  ; space
	ldx #$1f
@CharacterNameLoop:
	sta CharacterNames, X
	dex
	bpl @CharacterNameLoop
	lda #$ff
	ldx #$03
@ClassSelectionLoop:
	sta ClassSelections, X
	dex
	bpl @ClassSelectionLoop

	jsr InitializeCharacterSelect

	A16
@InputLoop:
	jsr PlaceHandOnCharacterSelectScreen
	wai
	jsr GetJoypadInputs
@CheckA:
	lda JoyTrigger1
	and #BUTTON_A
	beq @CheckB
	ldx PartyPosition
	cpx #$04
	beq @Done
	ldy ClassPosition
	sty ClassSelections, X
	ldx #$00
	stx InputPosition
	jsr DoNameInput
	bra @InputLoop
@CheckB:
	lda JoyTrigger1
	and #BUTTON_B
	beq @CheckLeft
	ldx PartyPosition
	cpx #$00
	beq @InputLoop
	dex
	stx PartyPosition
	ldx #$08
	stx InputPosition
	jsr DoNameInput
	bra @InputLoop
@CheckLeft:
	lda JoyTrigger1
	and #BUTTON_LEFT
	beq @CheckRight
	ldx ClassPosition
	dex
	bpl :+
	ldx #$05
:
	stx ClassPosition
	bra @InputLoop
@CheckRight:
	lda JoyTrigger1
	and #BUTTON_RIGHT
	beq @InputLoop
	ldx ClassPosition
	inx
	cpx #$06
	bne :+
	ldx #$00
:
	stx ClassPosition
	bra @InputLoop

@Done:
	rts
.endproc

.proc InitializeCharacterSelect
; Dungeon Map VRAM mapping
; 16 KB BG1 CHR       0x0000 word address
; 8 KB BG2 CHR        0x2000 word address
; 4 KB BG3 CHR        0x3000 word address
; 2 KB BG3 tilemap    0x3800 word address
; 8 KB BG1 tilemap    0x4000 word address
; 8 KB BG2 tilemap    0x5000 word address
; 16 KB sprites       0x6000 word address

; BG12NBA = $20
; BG34NBA = $03
; BG1SC   = $43
; BG2SC   = $53
; BG3SC   = $38

	php
	A8
	XY16

	lda #GAME_MODE_DUNGEON  ; character select uses mode 1, like the subscreen or a town shop
	sta GameMode

	lda #$8f                ; force v-blanking
	sta INIDISP
	stz NMITIMEN            ; disable NMI

	lda #$31                ; video mode 1, large character size for BG1 and BG2
	sta BGMODE
	lda #$20                ; see above VRAM mapping for details of these registers
	sta BG12NBA
	lda #$03
	sta BG34NBA
	lda #$43
	sta BG1SC
	lda #$53
	sta BG2SC
	lda #$38
	sta BG3SC
	lda #$14                ; enable sprites and BG3
	sta TM
	lda #$00                ; no background layers on subscreen
	sta TS
	stz HDMAEN              ; turn off any HDMA

	jsr ClearBG3TileBuffer
	; Load the font graphics.
	LONGCALL DMA2VRAML, BANK_TITLEGRAPHICS, FontChr, $3000, $1000

	stz CGADD                 ; start at CGRAM address $00
	ldx #$0000
@FontPaletteLoop:
	lda FontPalette, X        ; get a byte of palette data
	sta CGDATA                ; write it to CGRAM
	inx
	cpx #$0008                ; length of palette data
	bne @FontPaletteLoop

	; Load the sprites.
	LONGCALL DMA2VRAML, BANK_BATTLESPRITES, BattleSprites, $6000, $3000

	LONGCALL DMA2VRAML, BANK_TITLEGRAPHICS, HandSprite, $60E0, $0040
	LONGCALL DMA2VRAML, BANK_TITLEGRAPHICS, HandSprite + $40, $61E0, $0040

	lda #$80
	sta CGADD                 ; start at CGRAM address $80
	ldx #$0000
@BattleSpritePaletteLoop:
	lda BattleSpritePalettes, X ; get a byte of palette data
	sta CGDATA                ; write it to CGRAM
	inx
	cpx #$00C0                ; length of palette data
	bne @BattleSpritePaletteLoop

	ldx #$0000
@HandPaletteLoop:
	lda HandPalette, X
	sta CGDATA
	inx
	cpx #$0020                ; just one hand palette
	bne @HandPaletteLoop

	jsr DrawCharacterSelectScreen
	jsr PlaceHandOnCharacterSelectScreen
	jsr CopyBG3TileMapBufferToVRAM
	jsr CopyOamMirrorToOAM

	lda #$0f
	sta INIDISP             ; release forced blanking, set screen to full brightness
	lda #$81
	sta NMITIMEN            ; enable NMI, turn on automatic joypad polling

	plp
	rts
.endproc

.proc DrawCharacterSelectScreen
	php
	A8
	XY16
	CALL DrawWindow,  6,  1, 24,  6
	CALL DrawWindow,  1,  8, 13, 24
	CALL DrawWindow, 15,  8, 30, 24

	CALL DrawText, PartySelectString, 8, 1
	CALL DrawText, StatusString, 19, 8

	; Put character sprites in the party select window.
	ldy #$0000
	ldx #$0004        ; start at sprite 1, sprite 0 is the hand
	Temp = $00
@ClassLoop:
	; Leftmost class is at tile position 7, 3, which is 56, 21 pixels
	; So each character gets drawn at position 56 + 24*c, 21
	; The bottom half gets drawn at position 56 + 24*c, 37
	tya
	asl
	asl
	asl                   ; 8*c
	sta Temp
	asl                   ; 16*c
	adc Temp              ; 24*c
	adc #$38              ; 24*c + 56
	sta OamMirror, X      ; sprite 1 x coordinate
	sta OamMirror + 4, X  ; sprite 2 x coordinate
	inx
	lda #$15
	sta OamMirror, X      ; sprite 1 y coordinate
	lda #$25
	sta OamMirror + 4, X  ; sprite 2 y coordinate
	inx
	tya
	asl
	asl
	asl
	asl
	asl
	asl                   ; c*64 is the sprite tile index
	sta OamMirror, X      ; sprite 1 tile
	clc
	adc #$20
	sta OamMirror + 4, X  ; sprite 2 tile
	inx
	tya
	asl                   ; bits 1-3 are the palette, equal to c
	ora #$10              ; priority
	cpy #$0004
	bmi :+
	ora #$01              ; set the overflow bit of the tile index if c >= 4
:
	sta OamMirror, X      ; sprite 1 properties
	sta OamMirror + 4, X  ; sprite 2 properties
	inx

	inx
	inx
	inx
	inx                   ; move X past sprite 2
	iny
	cpy #$0006
	bne @ClassLoop

	ldy #$0000
@PartyLoop:
	lda ClassSelections, Y
	cmp #$ff
	beq @NoClass          ; skip characters that aren't selected yet

	jsr DrawCharacterAndClassNames

	lda #$10
	sta OamMirror, X      ; sprite 1 x
	sta OamMirror + 4, X  ; sprite 2 x
	inx
	tya
	asl
	asl
	asl
	asl
	asl                   ; p*32
	adc #$46              ; p*32 + 70
	sta OamMirror, X      ; sprite 1 y
	adc #$10
	sta OamMirror + 4, X  ; sprite 2 y
	inx
	lda ClassSelections, Y
	asl
	asl
	asl
	asl
	asl
	asl                   ; c*64 is the sprite tile index
	sta OamMirror, X      ; sprite 1 tile
	clc
	adc #$20
	sta OamMirror + 4, X  ; sprite 2 tile
	inx
	lda ClassSelections, Y
	asl                   ; bits 1-3 are the palette, equal to c
	ora #$10              ; priority
	sta OamMirror, X      ; sprite 1 properties
	sta OamMirror + 4, X  ; sprite 2 properties
	lda ClassSelections, Y
	cmp #$04
	bmi :+
	lda OamMirror, X      ; get the properties back
	ora #$01              ; set the overflow bit of the tile index if c >= 4
	sta OamMirror, X
	sta OamMirror + 4, X
:
	inx

	inx
	inx
	inx
	inx                   ; move X past sprite 2
	iny
	cpy #$04
	bne @PartyLoop

@NoClass:
	stz OamMirror + $200  ; set the high bit of x to 0 for these 20 sprites
	stz OamMirror + $201
	stz OamMirror + $202
	stz OamMirror + $203
	stz OamMirror + $204
	lda #$54
	sta OamMirror + $205  ; and the 21st sprite

	plp
	rts
.endproc

; This function is entirely dependent on the one above.  It assumes Y is set
; to the party index that we are drawing.
.proc DrawCharacterAndClassNames
	php
	phx

	A16
	; Draw the class name.
	phy                  ; we'll need this after drawing the text
	lda ClassSelections, Y
	and #$00ff
	asl
	asl
	asl
	adc #ClassNameStrings
	pha
	lda #$0008
	pha
	lda #$0005
	pha
	tya
	asl
	asl                   ; p*4
	adc #$000b            ; p*4 + 11
	pha
	jsr DrawFixedText
	pla
	pla
	pla
	pla
	ply                  ; need to restore Y

	; Draw the character name.
	tya                  ; so we can use it
	phy                  ; and push it right back
	asl
	asl
	asl
	adc #CharacterNames
	pha
	lda #$0008
	pha
	lda #$0005
	pha
	tya
	asl
	asl
	adc #$0009            ; p*4 + 9
	pha
	jsr DrawFixedText
	pla
	pla
	pla
	pla
	ply                   ; get our index back so we can return to the loop

	plx
	plp
	rts
.endproc

.proc PlaceHandOnCharacterSelectScreen
	php

	A8
	; Hand starts at 38, 25, 4 pixels down from the class and with a gap of 2 pixels to the right
	lda ClassPosition
	asl
	adc ClassPosition       ; c * 3
	asl
	asl
	asl                     ; c * 24
	adc #$26
	sta OamMirror
	lda #$19
	sta OamMirror + $01
	lda #$0e
	sta OamMirror + $02
	lda #$1c
	sta OamMirror + $03

	plp
	rts
.endproc

.proc DoNameInput
	php

	jsr ClearBG3TileBuffer
	jsr DrawKeyboard
	jsr DrawCharacterName

	A16
	XY8

	ldx #$00
	stx XPosition
	stx YPosition

@InputLoop:
	jsr PlaceHandOnKeyboard
	wai
	jsr GetJoypadInputs
@CheckA:
	lda JoyTrigger1
	and #BUTTON_A
	beq @CheckB
	ldx InputPosition
	cpx #$08
	beq @Done
	jsr TypeCharacter
	bra @InputLoop
@CheckB:
	lda JoyTrigger1
	and #BUTTON_B
	beq @CheckDPad
	ldx InputPosition
	cpx #00
	bne :+
	ldx PartyPosition
	ldy #$ff
	sty ClassSelections, X
	bra @Back
:
	jsr Backspace
	bra @InputLoop
@CheckDPad:
	jsr DoKeyboardMovement
	bra @InputLoop

@Done:
	ldx PartyPosition
	inx
	stx PartyPosition

@Back:
	jsr ClearBG3TileBuffer
	jsr DrawCharacterSelectScreen

	plp
	rts
.endproc

.proc DoKeyboardMovement
@CheckLeft:
	lda JoyTrigger1
	and #BUTTON_LEFT
	beq @CheckRight
	ldx XPosition
	dex
	bpl :+
	ldx #$0c
:
	stx XPosition
	rts
@CheckRight:
	lda JoyTrigger1
	and #BUTTON_RIGHT
	beq @CheckUp
	ldx XPosition
	inx
	cpx #$0d
	bne :+
	ldx #$00
:
	stx XPosition
	rts
@CheckUp:
	lda JoyTrigger1
	and #BUTTON_UP
	beq @CheckDown
	ldx YPosition
	dex
	bpl :+
	ldx #$05
:
	stx YPosition
	rts
@CheckDown:
	lda JoyTrigger1
	and #BUTTON_DOWN
	beq @End
	ldx YPosition
	inx
	cpx #$06
	bne :+
	ldx #$00
:
	stx YPosition
@End:
	rts
.endproc

.proc TypeCharacter
	php
	A8
	lda YPosition
	tay
	lda XPosition
	clc
@RowLoop:
	dey
	bmi :+
	adc #$0d
	bra @RowLoop
:
	asl                      ; Double the index because there are spaces between the keys
	tax
	lda AMString, X          ; read one character from the keyboard
	jsr WriteCharacter

	A8
	inc InputPosition

	plp
	rts
.endproc

.proc Backspace
	php
	A8
	dec InputPosition
	lda #$20 ; space
	jsr WriteCharacter

	plp
	rts
.endproc

.proc WriteCharacter
	pha
	lda PartyPosition
	asl
	asl
	asl
	adc InputPosition        ; store the character at the input position + party*8
	tax
	pla
	sta CharacterNames, X

	jsr DrawCharacterName

	rts
.endproc

.proc DrawCharacterName
	php
	AXY16

	lda PartyPosition
	and #$00ff
	asl
	asl
	asl
	adc #CharacterNames
	pha
	CALL DrawFixedText, 8, 13, 3 ; omit the first parameter because we already pushed it
	pla

	plp
	rts
.endproc

.proc DrawKeyboard
	php
	AXY16

	CALL DrawWindow, 9, 2, 21, 6
	CALL DrawWindow, 1, 8, 29, 22
	CALL DrawText, NameEntryString, 9, 8

	CALL DrawText, AMString, 3, 10
	CALL DrawText, NZString, 3, 12
	CALL DrawText, amString, 3, 14
	CALL DrawText, nzString, 3, 16
	CALL DrawText, NumString, 3, 18
	CALL DrawText, SymString, 3, 20

	lda PartyPosition
	and #$00ff
	tax
	lda ClassSelections, X
	and #$00ff
	asl
	asl
	asl
	adc #ClassNameStrings  ; index into this array of length-8 strings by class
	pha
	CALL DrawFixedText, 8, 13, 5
	pla

	; Move sprites 1-20 off the screen.
	AXY8
	ldx #$05                          ; Y coordinate of sprite 1
	lda #$e0
@SpriteLoop:
	sta OamMirror, X
	inx
	inx
	inx
	inx
	cpx #$55                          ; sprite 21
	bne @SpriteLoop

	ldy PartyPosition
	lda ClassSelections, Y            ; get the class for the current character
	asl
	asl                               ; 4 bytes per sprite, and
	asl                               ; 2 sprites per class (top and bottom)
	adc #$04                          ; skip over the hand sprite
	tax
	lda #$50                          ; x position of the character sprite
	sta OamMirror, X
	sta OamMirror + 4, X              ; x position of the bottom of character sprite
	lda #$16                          ; y position
	sta OamMirror + 1, X
	lda #$26                          ; y position bottom
	sta OamMirror + 5, X

	plp
	rts
.endproc

.proc PlaceHandOnKeyboard
	php

	A8
	; Hand starts at 6, 78, pointing at the A
	lda XPosition
	asl
	asl
	asl
	asl                     ; x * 16
	adc #$06
	sta OamMirror
	lda YPosition
	asl
	asl
	asl
	asl                     ; y * 16
	adc #$4e
	sta OamMirror + $01
	lda #$0e
	sta OamMirror + $02
	lda #$1c
	sta OamMirror + $03

	plp
	rts
.endproc

; Draws a box on the screen, from x1 to x2, y1 to y2, where the arguments are passed
; on the stack in that order.
.proc DrawWindow
	; Stack variables
	x1 = $0B
	y1 = $09
	x2 = $07
	y2 = $05
	; Window characters
	BorderTL = $c9
	BorderT  = $cb
	BorderTR = $bb
	BorderL  = $ca
	BorderR  = $bc
	BorderBL = $cc
	BorderB  = $b9
	BorderBR = $c8
	Space    = $20

	phd
	tsc
	tcd
	php
	AXY16
	lda y1                        ; calculate offset into BG3 tilemap
	asl
	asl
	asl
	asl
	asl                           ; multiply Y by 32
	clc
	adc x1                        ; we now have the word address, so
	asl                           ; multiply by 2 to get the byte address
	tax                           ; put the address in X
	lda x2
	sec
	sbc x1
	pha                           ; push the tile count
	pea BorderTL                  ; push the top border tiles
	pea BorderT
	pea BorderTR
	jsr DrawWindowRow             ; Draw the top row
	plx
	plx
	plx

	; Now we draw the main part of the window.  The tile count is the same, so we just
	; have to change the tiles.  They've already been pushed onto the stack, and rather
	; than pop them off, we can just set them with stack-relative addressing.
	pea BorderL
	pea Space
	pea BorderR
	ldy y1
	iny                           ; set Y to the second row
@RowLoop:
	tya
	asl
	asl
	asl
	asl
	asl
	clc
	adc x1
	asl                           ; get the byte address of the beginning of the row again
	tax
	jsr DrawWindowRow
	iny
	cpy y2
	bmi @RowLoop

	plx
	plx
	plx
	pea BorderBL                 ; Now we do the bottom row.
	pea BorderB
	pea BorderBR
	tya                           ; y should already be equal to y2
	asl
	asl
	asl
	asl
	asl
	clc
	adc x1
	asl                           ; get the byte address of the beginning of the row again
	tax
	jsr DrawWindowRow

	; Clean up the stack!
	pla
	pla
	pla
	pla
	plp
	pld
	rts
.endproc

.proc DrawWindowRow
	TileCount  = $0B
	LeftTile   = $09
	MiddleTile = $07
	RightTile  = $05
	phd
	tsc
	tcd

	lda LeftTile                  ; begin the row
	and $00ff                     ; the tile index is just one byte on the stack, but two bytes in VRAM
	sta BG3TileMapBuffer, X       ; high byte stores palette/priority/flipping, not needed for this
	inx
	inx                           ; 2 bytes
	phy
	ldy #$0001
	lda MiddleTile                ; space
	and $00ff
@TopLoop:
	sta BG3TileMapBuffer, X
	inx
	inx                           ; 2 bytes
	iny                           ; but the coordinate only increased by 1
	cpy TileCount
	bmi @TopLoop
	lda RightTile                 ; complete the row
	and $00ff
	sta BG3TileMapBuffer, X
	ply

	pld
	rts
.endproc

.proc DrawText
	pText  = $09
	xCoord = $07
	yCoord = $05
	phd
	tsc
	tcd
	php
	AXY16

	lda yCoord              ; formula is 2 * (y*32 + x), 2 bytes per tile, 32 tiles across
	asl
	asl
	asl
	asl
	asl
	clc
	adc xCoord
	asl
	tax

	ldy #$0000
@Loop:
	lda (pText), Y          ; fetch a character
	and #$00ff              ; we just want one byte of text at a time
	beq @Done               ; null-terminated string
	sta BG3TileMapBuffer, X ; we have to store two bytes for the tile
	iny                     ; next character
	inx                     ; and next tile location
	inx
	bra @Loop

@Done:
	plp
	pld
	rts
.endproc

.proc DrawFixedText
	pText  = $0B
	Length = $09
	xCoord = $07
	yCoord = $05
	phd
	tsc
	tcd
	php
	AXY16

	lda yCoord              ; formula is 2 * (y*32 + x), 2 bytes per tile, 32 tiles across
	asl
	asl
	asl
	asl
	asl
	clc
	adc xCoord
	asl
	tax

	ldy #$0000
@Loop:
	lda (pText), Y          ; fetch a character
	and #$00ff              ; we just want one byte of text at a time
	sta BG3TileMapBuffer, X ; we have to store two bytes for the tile
	iny                     ; next character
	inx                     ; and next tile location
	inx
	cpy Length
	bne @Loop

	plp
	pld
	rts
.endproc

.proc ClearBG3TileBuffer
	php

	AXY16
	; Zero out the BG3 tilemap buffer.
	lda #$0001
	sta BG3TileMapBufferDirty     ; 2-byte write to a 1-byte variable, but the second byte will get overwritten immediately
	ldx #$0000
@BG3Loop:
	stz BG3TileMapBuffer, X
	inx
	inx
	cpx #$0800
	bne @BG3Loop

	plp
	rts
.endproc

; Zeroes out VRAM starting from a word address given in the A register and a word count
; given in the X register.  A,X,Y assumed to be 16-bit.
.proc ZeroVRAM
	sta VMADDL
@Loop:
	stz VMDATAL
	dex
	bne @Loop
	rts
.endproc
