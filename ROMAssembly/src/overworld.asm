.p816
.a8
.i16

.include "defines.inc"
.include "macros.inc"
.include "registers.inc"
.include "joypad.inc"

.export LoadOverworld
.export DoOverworldMovement
.export SetOverworldCharacterObj
.export SetOverworldVehicleObj
.export CopyTileMapBufferToVRAM
.export SetMode7Matrix
.export SetupAirshipMode7HDMA

.import Sine
.import Cosine

.import DMA2VRAML : far
.import AirshipMode7Tables : far

.segment "OVERWORLD"
CompressedOverworld: .incbin "data/overworld-map.bin"            ; ~16 KB, varies with compression
.segment "OWGRAPHICS"
OverworldChr:        .incbin "graphics/overworld-chr.m7"         ; 16 KB
OverworldSprites:    .incbin "graphics/overworld-sprites.4bpp"   ; 16 KB

.segment "CODE"

OverworldTilemaps:       .incbin "data/overworld-tilemaps.bin"
OverworldTileProperties: .incbin "data/overworld-tileproperties.bin"
OverworldSpritePalettes: .incbin "graphics/overworld-sprite-palettes.pal"
OverworldPalette:        .incbin "graphics/overworld-map-palette.pal"

MAPPOSX  = $1000 ; position in pixels
MAPPOSY  = $1002
MAPANGLE = $1004 ; mode 7 angle of rotation in bytians (256 to a circle)
MAPZOOM  = $1006 ; mode 7 zoom, fixed point 8.8

DirDown  = 1     ; which direction are we moving or facing
DirUp    = 2
DirLeft  = 3
DirRight = 4
MOVEDIR  = $1008
FACEDIR  = $1009

Vehicle_Foot    = 1     ; it is not important that these be flags, they just need to be distinct
Vehicle_Canoe   = 2     ; but I made them equal to the walkability flags, which might be useful
Vehicle_Ship    = 4     ; we don't even need a specific value for "foot", just any value that
Vehicle_Airship = 8     ; isn't the other values
CURR_VEHICLE    = $100A ; are we in a vehicle?
MOVE_SPEED      = $100B ; how many pixels per frame, 1 for walking, 2 for ship, 4 for airship, should be 2 bytes for convenience
CHARACTER_POS   = $100D ; 2 bytes, $YYXX map coordinates
MOVE_TO_POS     = $100F ; 2 bytes, where are we moving to
SHIP_POS        = $1011 ; 2 bytes
AIRSHIP_POS     = $1013 ; 2 bytes
AIRSHIP_TRANSITION = $1015 ; 2 bytes
CURR_CLASS      = $1017 ; 1 byte, this is temporary, will become current party member

CharacterSprite  = OamMirror     ; sprite memory locations
AirshipSprite    = OamMirror + 4
ShipSprite       = OamMirror + 8
CharacterSpriteH = OamMirror + $200
AirshipSpriteH   = OamMirror + $200 ; these need to be shifted
ShipSpriteH      = OamMirror + $200

START_POSITION   = $A599    ; start at $99, $A5, and the midpoint of the tile (+8 pixels)
START_POSITION_X = $0998
START_POSITION_Y = $0A58
SHIP_INIT        = $A998    ; don't forget to move this to Pravoka
AIRSHIP_INIT     = $A79A    ; and this to Ryukahn Desert

.proc LoadOverworld
	A8
	lda #GAME_MODE_OVERWORLD
	sta GameMode

	lda #$8f                ; force v-blanking
	sta INIDISP
	stz NMITIMEN            ; disable NMI

	stz MOVEDIR             ; be still
	lda #DirDown            ; face down
	sta FACEDIR
	lda #Vehicle_Foot       ; be on foot
	sta CURR_VEHICLE
	stz CURR_CLASS          ; be fighter
	AXY16
	ldx #START_POSITION_X   ; set the initial scroll
	stx MAPPOSX
	ldy #START_POSITION_Y
	sty MAPPOSY
	lda #START_POSITION     ; and map coords
	sta CHARACTER_POS
	lda #SHIP_INIT          ; and ship coords
	sta SHIP_POS
	lda #AIRSHIP_INIT       ; and airship coords
	sta AIRSHIP_POS
	lda #$00                ; zero the airship transition
	sta AIRSHIP_TRANSITION
	stz MAPANGLE            ; initial rotation (none)
	lda #$0040              ; initial zoom (1x)
	sta MAPZOOM

	jsr LoadOverworldCharacters
	jsr LoadOverworldPalette
	jsr LoadOverworldSprites
	jsr LoadOverworldSpritePalettes
	jsr LoadOverworldMapData

	jsr SetupVideo

	A8
	lda #$81
	sta NMITIMEN            ; enable NMI, turn on automatic joypad polling

	rts
.endproc

.proc LoadOverworldCharacters
	; There are 256 8x8 characters that make up the graphics for the overworld.
	; All we need to do is shove them into VRAM starting at address 0.
	A8
	XY16
	stz MDMAEN                  ; reset DMA
	lda #$80                    ; VRAM increment on write to VMDATAH
	sta VMAINC
	ldx #$0000
	stx VMADDL                  ; start at VRAM address 0
	lda #<VMDATAH               ; write to VRAM high register (Mode 7 graphics)
	sta DMA0ADDB
	ldx #OverworldChr & $ffff   ; the OverworldChr address is long, so we mask it
	stx DMA0ADDAL               ; read from overworld CHR data
	lda #BANK_OWGRAPHICS        ; which is in this bank
	sta DMA0ADDAH
	ldx #$4000                  ; write 16 KB (64 bytes * 256 characters)
	stx DMA0AMTL
	stz DMA0PARAM               ; configure DMA0 for A->B, inc A address, 1 byte to 1 register
	lda #$01                    ; DMA0 channel
	sta MDMAEN                  ; enable
	rts
.endproc

.proc LoadOverworldPalette
	A16
	lda #$0000      ; clear the high byte
	A8
	XY16
	lda #BANK_MAIN  ; set data bank to main
	pha
	plb

	stz CGADD       ; start at CGRAM address 0
	ldx #$0000
@Loop:
	lda OverworldPalette, X ; get a byte of palette data
	sta CGDATA              ; write it to CGRAM
	inx
	cpx #$0080              ; length of palette data
	bne @Loop

	rts
.endproc

.proc LoadOverworldMapData
	; Here we decompress the map data.  The map is 256x256, but we will only load 64 rows
	; at a time, centered around the player's Y coordinate.  Each map row will go into the
	; "slot" of the actual row mod 64, so as you scroll up and down, the rows behind you
	; get cycled out for rows in front of you.
	TempMaxY = $00              ; Keep track of the maximum Y position
	A16
	lda MAPPOSY				    ; get the player's Y position
	lsr                         ; divide by 16 to get the tile position
	lsr
	lsr
	lsr
	AXY8
	clc
	adc #$1f                    ; max Y position is 31 rows higher (farther down)
	sta TempMaxY
	sec
	sbc #$40                    ; min Y position is 64 rows below max.  We go farther up than
	tay                         ; down because we can see farther up due to the perspective.
@Loop:
	jsr DecompressMapRow           ; Decompress one row
	jsr CopyMapRowToBuffer         ; Copy the decompressed row to the tile map buffer
	jsr CopyTileMapBufferRowToVRAM ; Put it in VRAM
	iny
	cpy TempMaxY
	bne @Loop
	stz TileMapBufferDirty         ; this gets set by all the buffering, but we don't want to
	                               ; copy the buffer again when we enable NMI
	rts
.endproc

.proc DecompressMapRow
	; Map rows are referenced by a pointer table, 2 bytes per row, and the rows
	; themselves are RLE compressed.  There are 128 possible tiles, so the lower 7 bits
	; represent the tile that appears next.  If the MSB is not set, then the byte simply
	; represents one tile.  If the MSB is set, then the following byte is the number of
	; times the tile should appear.  A value of 0 means the tile appears 256 times, and
	; takes up the entire row.  Rows are terminated by $FF, even if the whole row is the
	; same tile.
	;
	; The value in the Y register is the row we want to decompress.
	; We will decompress it into the (Y mod 64)th row of uncompressed map data.
	TempSrc = $02              ; Keep track of where we're reading from
	phy                        ; Save Y which will definitely be overwritten by decoding
	php                        ; Save the bitness of the registers
	A8
	lda #BANK_OVERWORLD        ; Set data bank to overworld source
	pha
	plb
	AXY16
	phy                        ; remember the actual row
	tya
	and #$003f                 ; row mod 64
	xba                        ; times the row length (256)
	tax                        ; X now points to the destination row buffer
	pla                        ; restore the actual row
	asl                        ; row# times 2 to get the pointer
	tay
	lda CompressedOverworld, Y ; get the pointer
	tay                        ; Y now points to the compressed row data

@Loop:
	A8
	lda CompressedOverworld, Y
	iny
	cmp #$ff                   ; are we done?
	bne :+
	plp                        ; Restore the bitness before
	ply                        ; restoring Y, otherwise we pop the wrong number of bytes
	rts
:
	pha                        ; remember the tile
	cmp #$80                   ; test the MSB
	bcs :+
                               ; if we're here, just one tile
	pla                        ; retrieve the tile
	sta OverworldMapL, X       ; store it
	inx                        ; bump it
	bra @Loop                  ; loop it
:                              ; if we're here, we repeat the tile
	lda #$00                   ; we need to clear
	xba                        ; the high byte of A, so that...
	lda CompressedOverworld, Y ; get the number of repeats
	iny
	sty TempSrc                ; remember where we were reading from
	tay                        ; ...the high byte of Y will be clear
	bne :+                     ; Y will count down
	                           ; if the count is 0, the count is actually 256
	ldy #$0100                 ; so fix it (this would "just work" if Y were 8-bit, but it isn't, and we need Y to be 16-bit)
:
	pla                        ; get the tile back
	and #$7f                   ; clear the repeat flag
@LoopRepeat:
	sta OverworldMapL, X       ; store it
	inx                        ; bump it
	dey                        ; loop it
	bne @LoopRepeat
	ldy TempSrc                ; restore where we were reading from
	bra @Loop
.endproc

.proc CopyMapRowToBuffer
	; The value in the Y register is the row we want to copy.
	; We will copy the (Y mod 64)th row of uncompressed map data into the tile map buffer.
	; We need to do a lot of math, so we'll be using variables here instead of juggling
	; registers constantly.
	TempRowPointer    = $02
	TempBufferPointer = $04
	TempCounter       = $06
	TempRowPos        = $08
	phy
	php
	A8
	lda #BANK_MAIN             ; set data bank for the tilemaps
	pha
	plb
	A16
	tya
	and #$3f                   ; row mod 64
	A8
	pha                        ; save the row index
	lda #$01                   ; 1 means the dirty buffer contains a row
	sta TileMapBufferDirty
	pla                        ; restore the row index
	sta TileMapBufferIndex
	A16
	xba                        ; multiply by the row length (256)
	sta TempRowPointer
	lda MAPPOSX                ; get the X position, divide by 16 to get the tile position
	lsr
	lsr
	lsr
	lsr
	sec
	sbc #$001f                 ; subtract 31 to get the leftmost tile to copy
	and #$00ff                 ; if we underflowed, we just want to wrap
	clc
	adc TempRowPointer         ; add the row pointer, now we have the index of the leftmost tile
	sta TempBufferPointer      ; save the buffer pointer
	stz TempCounter            ; loop variable
	XY16
@Loop:
	A16
	lda TempBufferPointer            ; We need to calculate the tile index in the decompressed map.
	and #$00ff                       ; just the x-coordinate
	adc TempCounter                  ; This is from the start position, plus our loop counter,
	and #$00ff                       ; and we have to wrap around to stay in the same row.
	sta TempRowPos                   ; hang onto this for later
	lda TempBufferPointer            ; now get the buffer pointer again
	and #$ff00                       ; just the row
	clc
	adc TempRowPos                   ; add the row position
	tax                              ; put it in X
	lda OverworldMapL, X             ; get the tile
	and #$00ff                       ; just one byte
	tay                              ; put it in Y
	A8
	lda OverworldTilemaps, Y         ; get the upper-left character
	pha                              ; save it
	lda OverworldTilemaps + $80, Y   ; get the upper-right character
	pha                              ; save it
	lda OverworldTilemaps + $100, Y  ; get the lower-left character
	pha                              ; save it
	lda OverworldTilemaps + $180, Y  ; get the lower-right character
	pha                              ; save it
	A16
	lda TempRowPos                   ; what's our position in the row
	and #$3f                         ; mod 64
	asl                              ; times 2, this is our index into the buffer
	tay                              ; put it in Y
	A8
	pla                              ; grab the lower-right character
	sta TileMapBuffer + $81, Y       ; store it to the buffer
	pla                              ; grab the lower-left character
	sta TileMapBuffer + $80, Y       ; store it to the buffer
	pla                              ; grab the upper-right character
	sta TileMapBuffer + 1, Y         ; store it to the buffer
	pla                              ; grab the upper-left character
	sta TileMapBuffer, Y             ; store it to the buffer
	inc TempCounter
	lda TempCounter
	cmp #$40                         ; do this 64 times
	bne @Loop

	plp
	ply
	rts
.endproc

.proc CopyTileMapBufferRowToVRAM
	; We're going to copy 64 map tiles into VRAM.  The buffer is laid out so that the
	; tiles are aligned with the Mode 7 scroll, so there's no offsetting necessary
	; here, and the two rows of tilemaps are contiguous in memory.  So one DMA shot
	; straight into VRAM, 256 bytes.
	; The Y register holds the map row to copy from.
	php
	A16
	tya
	and #$003f                  ; row mod 64
	xba                         ; times 256
	sta VMADDL                  ; is the VRAM address
	XY16
	A8
	stz VMAINC                  ; VRAM increment on write to VMDATAL
	stz MDMAEN                  ; reset DMA

	lda #<VMDATAL               ; write to VRAM low register (Mode 7 tilemaps)
	sta DMA0ADDB
	ldx #TileMapBuffer
	stx DMA0ADDAL               ; read from the tilemap buffer
	lda #OverworldMapBank       ; which is in this bank
	sta DMA0ADDAH
	ldx #$0100                  ; write 256 bytes
	stx DMA0AMTL
	stz DMA0PARAM               ; configure DMA0 for A->B, inc A address, 1 byte to 1 register

	lda #$01                    ; DMA0 channel
	sta MDMAEN                  ; enable
	plp
	rts
.endproc

.proc CopyMapColumnToBuffer
	; The value in the X register is the row we want to copy.
	; This will be a little more straightforward than copying rows, because we can just start from
	; the first decompressed map row and go to the last one; the correct rows are already in the
	; correct place in the decompressed map data.
	TempBufferPointerLeft  = $04
	TempBufferPointerRight = $06
	TempColPos             = $08
	php
	A8
	lda #BANK_MAIN             ; set data bank for the tilemaps
	pha
	plb
	A16
	lda #TileMapBuffer
	sta TempBufferPointerLeft  ; initialize the buffer pointer
	clc
	adc #$80                   ; initialize the other buffer pointer
	sta TempBufferPointerRight
	A8
	txa
	sta TempColPos             ; save this
	and #$3f                   ; mod 64 will be the column index into VRAM
	sta TileMapBufferIndex     ; store the index
	lda #$02                   ; 2 means the buffer has a column
	sta TileMapBufferDirty

	XY16
	ldy #$00
@Loop:
	A16
	tya                        ; the row index
	xba                        ; times 256
	adc TempColPos             ; plus the column index
	tax                        ; is the tile index

	lda OverworldMapL, X       ; get the tile
	and #$00ff                 ; just one byte
	tax                        ; put it in X

	A8
	lda OverworldTilemaps, X         ; get the upper-left character
	sta (TempBufferPointerLeft)      ; save it
	inc TempBufferPointerLeft
	lda OverworldTilemaps + $100, X  ; get the lower-left character
	sta (TempBufferPointerLeft)      ; save it
	inc TempBufferPointerLeft
	lda OverworldTilemaps + $80, X   ; get the upper-right character
	sta (TempBufferPointerRight)     ; save it
	inc TempBufferPointerRight
	lda OverworldTilemaps + $180, X  ; get the lower-right character
	sta (TempBufferPointerRight)     ; save it
	inc TempBufferPointerRight

	iny                              ; next row
	cpy #$40                         ; do this 64 times
	bne @Loop

	plp
	rts
.endproc

.proc CopyTileMapBufferColumnToVRAM
	; Same as the above function, except we're doing a column of map tiles.  This will
	; need to be two DMA transfers, one for each column of 8x8 characters.
	; The X register holds the map column to copy from.
	php
	A16
	txa
	and #$003f                  ; column mod 64
	asl                         ; times 2
	sta VMADDL                  ; is the VRAM address for the left column
	pha                         ; save this for later

	XY16
	A8
	lda #$02
	sta VMAINC                  ; increment VRAM address by $80 (one row)
	stz MDMAEN                  ; reset DMA
	lda #<VMDATAL               ; write to VRAM low register (Mode 7 tilemaps)
	sta DMA0ADDB
	ldy #TileMapBuffer
	sty DMA0ADDAL               ; read from the tilemap buffer
	lda #OverworldMapBank       ; which is in this bank
	sta DMA0ADDAH
	ldy #$0080                  ; write 128 bytes
	sty DMA0AMTL
	stz DMA0PARAM               ; configure DMA0 for A->B, inc A address, 1 byte to 1 register
	lda #$01                    ; DMA0 channel
	sta MDMAEN                  ; enable

	; Copy the right column
	A16
	pla                         ; fetch the VRAM address again
	adc #$01                    ; add 2 bytes to move over one column
	sta VMADDL                  ; this is the VRAM address for the right column
	A8
	stz MDMAEN                  ; reset DMA
;   I think this can all be skipped because it's already configured above
;	lda #<VMDATAL               ; write to VRAM low register (Mode 7 tilemaps)
;	sta DMA0ADDB
;	ldy #TileMapBuffer
;	sty DMA0ADDAL               ; read from the tilemap buffer
;	lda #OverworldMapBank       ; which is in this bank
;	sta DMA0ADDAH
;   We need to reset the byte count, though
	ldy #$0080                  ; write 128 bytes
	sty DMA0AMTL
;	stz DMA0PARAM               ; configure DMA0 for A->B, inc A address, 1 byte to 1 register
	lda #$01                    ; DMA0 channel
	sta MDMAEN                  ; enable

	plp
	rts
.endproc

.proc CopyTileMapBufferToVRAM
	; Check if the tilemap buffer is dirty, then determine whether to
	; copy a row or column, and do so.
	php
	A8
	XY16
	lda TileMapBufferDirty
	cmp #$01
	bne @CheckColumn
	ldy TileMapBufferIndex
	jsr CopyTileMapBufferRowToVRAM
	bra @Done

@CheckColumn:
	cmp #$02
	bne @Done
	ldx TileMapBufferIndex
	jsr CopyTileMapBufferColumnToVRAM
	; bra Done

@Done:
	stz TileMapBufferDirty      ; zero the dirty flag
	plp
	rts
.endproc

.proc LoadOverworldSprites
	; There are a 12 character classes and 3 vehicles, each with 6 frames of animation.
	; Each of these is a 16x16 sprite taking up 128 bytes.  All told, 12 KB of data
	; (with room at the end for one more set of 6).
	XY16
	LONGCALL DMA2VRAML, BANK_OWGRAPHICS, OverworldSprites & $ffff, $6000, $4000
	rts
.endproc

.proc LoadOverworldSpritePalettes
	A16
	lda #$0000      ; clear the high byte
	A8
	XY16
	lda #BANK_MAIN  ; set data bank to main
	pha
	plb

	lda #$80
	sta CGADD       ; start at CGRAM address $80
	ldx #$0000      ; and palette 0
@PartyLoop:
	lda OverworldSpritePalettes, X ; get a byte of palette data
	sta CGDATA                     ; write it to CGRAM
	inx
	cpx #$0080                     ; length of palette data for 4 party members
	bne @PartyLoop

	lda #$C0
	sta CGADD       ; start at CGRAM address $C0
	ldx #$0180      ; also sprite palette address $C0, vehicles
@VehicleLoop:
	lda OverworldSpritePalettes, X ; get a byte of palette data
	sta CGDATA                     ; write it to CGRAM
	inx
	cpx #$01E0                     ; length of palette data for 3 vehicles
	bne @VehicleLoop

	rts
.endproc

.proc SetupVideo
	A8

	lda #$07
	sta BGMODE
	stz M7SEL               ; wrap tiles, no flipping
	jsr SetMode7Matrix      ; set up Mode 7 transform parameters

	lda #$63                ; sprites are 16x16 and 32x32, sprite RAM is at $C000 (but word address $6000)
	sta OBJSEL

	lda #$11                ; enable BG1 and sprites
	sta TM
	stz CGADSUB             ; disable color math

	lda #$0f
	sta INIDISP             ; release forced blanking, set screen to full brightness

	rts
.endproc

.proc DoOverworldMovement
	A16
	XY8

@CheckRButton:
	lda JoyTrigger1         ; see if R was just pressed
	and #BUTTON_R
	beq @CheckMoving
	A8
	lda CURR_CLASS
	inc
	and #$03
	sta CURR_CLASS
	A16

@CheckMoving:
	ldx MOVEDIR             ; see if we're already moving
	bne @MoveOK

	; if we're not moving, we're going to see if we're pressing the A button
	; and we're on the airship
@CheckAButton:
	lda JoyPad1
	and #BUTTON_A
	beq @CheckUpButton
	ldx CURR_VEHICLE
	cpx #Vehicle_Airship    ; are we currently flying?
	bne @CheckTakeoff
	jsr LandAirship         ; not anymore we're not
	bra @CheckUpButton       ; might as well try to walk as soon as we land
@CheckTakeoff:
	lda CHARACTER_POS
	cmp AIRSHIP_POS         ; are we standing on the airship?
	bne @CheckUpButton
	jsr TakeoffAirship

	; check the dpad, if any of the directional buttons are pressed,
	; move the screen accordingly
@CheckUpButton:
	lda JoyPad1                         ; read joypad buttons pressed
	and #BUTTON_UP
	beq @CheckDownButton
	ldx #DirUp
	stx FACEDIR
	bra @Move

@CheckDownButton:
	lda JoyPad1
	and #BUTTON_DOWN
	beq @CheckLeftButton
	ldx #DirDown
	stx FACEDIR
	bra @Move

@CheckLeftButton:
	lda JoyPad1
	and #BUTTON_LEFT
	beq @CheckRightButton
	ldx #DirLeft
	stx FACEDIR
	bra @Move

@CheckRightButton:
	lda JoyPad1
	and #BUTTON_RIGHT
	beq @Done
	ldx #DirRight
	stx FACEDIR
;	bra @Move

@Move:
	jsr GetTileMoveCoords
	jsr CanMove
	cmp #$0001
	bne @Done
	jsr CalculateMovementSpeed
@MoveOK:
	ldx FACEDIR
	stx MOVEDIR

@MoveUp:
	cpx #DirUp
	bne @MoveDown
	lda MAPPOSY
	sec
	sbc MOVE_SPEED
	and #$0fff       ; wrap around
	sta MAPPOSY
	bra @DoneMoving

@MoveDown:
	cpx #DirDown
	bne @MoveLeft
	lda MAPPOSY
	clc
	adc MOVE_SPEED
	and #$0fff       ; wrap around
	sta MAPPOSY
	bra @DoneMoving

@MoveLeft:
	cpx #DirLeft
	bne @MoveRight
	lda MAPPOSX
	sec
	sbc MOVE_SPEED
	and #$0fff       ; wrap around
	sta MAPPOSX
	bra @DoneMoving

@MoveRight:
	cpx #DirRight
	bne @Done
	lda MAPPOSX
	clc
	adc MOVE_SPEED
	and #$0fff       ; wrap around
	sta MAPPOSX
;	bra @DoneMoving

@DoneMoving:
	and #$000f       ; get the count of pixels walked
	cmp #$0008       ; offset by 8 because we're in the "center" of a tile
	bne @Done         ; if it wasn't evenly divisible by 16, we're still walking
	ldx #$00         ; otherwise we stop walking
	stx MOVEDIR
	jsr LandedOnSquare

@Done:
	rts
.endproc

.proc GetTileMoveCoords
	; Loads the coordinates of the map tile we are moving toward into A as $YYXX.
	php
	AXY8
	A16
	lda CHARACTER_POS ; get the position we're moving from
	ldx FACEDIR
	cpx #DirUp        ; if we're going up
	bne @CheckDown
	sec
	sbc #$0100        ; decrease the Y coordinate
	bra @VerticalDone
@CheckDown:
	cpx #DirDown      ; if we're going down
	bne @Horizontal
	clc
	adc #$0100        ; increase the Y coordinate
@VerticalDone:
	sta MOVE_TO_POS   ; save the coords for reference
	plp
	rts

@Horizontal:
	and #$ff00        ; save the Y coordinate, because we need to reset it in case we wrap
	pha               ; put it on the stack
	lda CHARACTER_POS ; get the whole position back
	cpx #DirLeft      ; if we're going left
	bne @CheckRight
	dec               ; decrease the X coordinate
	and #$00ff        ; isolate X
	ora 1, S          ; get the Y coordinate back
	bra @HorizontalDone
@CheckRight:
	cpx #DirRight     ; if we're going right
	bne @HorizontalDone
	inc               ; increase the X coordinate
	and #$00ff        ; isolate X
	ora 1, S          ; get the Y coordinate back
@HorizontalDone:
	sta MOVE_TO_POS   ; save the coords for reference
	pla               ; pop the stack back
	lda MOVE_TO_POS   ; retrieve the coords to "return" them
	plp
	rts
.endproc

.proc CanMove
	; Test if we can move to a square whose coordinates are stored in A.
	TempTileProp = $0A
	phx
	php
	XY8
	ldy CURR_VEHICLE          ; Get the vehicle we're in
	cpy #Vehicle_Airship      ; Is it the airship?
	bne @NotAirship
	bra @CanMove              ; If we're in the airship, we can move anywhere.
@NotAirship:                  ; Otherwise, we need to know what tile we're moving to.
	jsr GetTileProperties
	sta TempTileProp          ; save them
	XY8
	cpy #Vehicle_Ship         ; Y still has the vehicle, is it the ship?
	bne @CanMoveFoot
@CanMoveShip:
	and #OWTP_NoShip          ; can we sail?
	bne @CantSail
	bra @CanMove              ; Iiiiiiiiiiiiiiiii'm sailiiiiiiiiing awaaaaaaaaaaaaaaay
@CantSail:
	lda TempTileProp
	and #OWTP_Dock            ; Are we docking?
	bne @Dock
	lda TempTileProp
	and #OWTP_NoCanoe         ; I can row a boat, canoe?
	bne @CantDock
@DockCanoe:
	ldy #Vehicle_Canoe
	sty CURR_VEHICLE
	bra @StopShip
@Dock:
	ldy #Vehicle_Foot         ; set our vehicle to foot
	sty CURR_VEHICLE
@StopShip:
	lda CHARACTER_POS         ; set the ship's location to where we are now
	sta SHIP_POS
	bra @CanMove              ; and we're walking
@CantDock:
	bra @CantMove
@CanMoveFoot:
	lda TempTileProp
	and #OWTP_NoWalk          ; can we walk?
	bne @CantWalk
	ldy #Vehicle_Foot         ; make sure we're walking
	sty CURR_VEHICLE          ; in case we're getting out of the canoe
	bra @CanMove
@CantWalk:
	lda TempTileProp
	and #OWTP_NoCanoe         ; canoe?
	bne @CantCanoe
	bra @CanMove              ; we don't get in the canoe until we land on the square
@CantCanoe:
	lda MOVE_TO_POS
	cmp SHIP_POS              ; are we getting on the ship?
	beq @CanMove
@CantMove:
	lda #$0000                ; can't move
	bra @Done
@CanMove:
	lda #$0001                ; can move
@Done:
	plp
	plx
	rts

.endproc

.proc GetTileProperties
	; For the map tile with coords $YYAA in the A register,
	; return the tile properties in the A register.
	php
	AXY16
	and #$3fff                ; Y-coordinate mod 64
	tax
	lda OverworldMapL, X      ; get the tile
	and #$00ff                ; clear the high byte
	clc
	asl                       ; and multiply by 2
	tax                       ; before putting it in X
	lda OverworldTileProperties, X ; get the tile properties
	plp
	rts
.endproc

.proc CalculateMovementSpeed
.a16
.i8
	phx
	ldx CURR_VEHICLE          ; which vehicle is the main factor here
	lda JoyPad1
	and #BUTTON_B             ; and if we're pressing B
	bne @PressingB

	cpx #Vehicle_Airship
	bne @NotAirship
	lda #$0004
	bra @Done
@NotAirship:
	cpx #Vehicle_Ship
	bne @NotShip
	lda #$0004
	bra @Done
@NotShip:
	lda #$0002
	bra @Done

@PressingB:
	cpx #Vehicle_Airship
	bne @NotAirshipB
	lda #$0002
	bra @Done
@NotAirshipB:
	cpx #Vehicle_Ship
	bne @NotShipB
	lda #$0002
	bra @Done
@NotShipB:
	lda #$0001

@Done:
	sta MOVE_SPEED
	plx
	rts

.endproc

.proc LandedOnSquare
	; First thing is to load map data into WRAM and map graphics into VRAM.
	; We decompress a new map row into WRAM if we were walking up or down.
	TempX = $00
	TempY = $02
	TempTileProp = $04
	A16
	lda MAPPOSX               ; we'll calculate the map's X coordinate
	lsr                       ; by dividing the pixel position by 16
	lsr
	lsr
	lsr
	sta TempX
	lda MAPPOSY               ; and the Y coordinate
	lsr
	lsr
	lsr
	lsr
	sta TempY
	xba                       ; put the Y coordinate in the high byte
	ora TempX                 ; and the X coordinate in the low byte
	sta CHARACTER_POS         ; store the character's position as $YYXX for reference

	A8
	lda FACEDIR
@CheckUp:
.a8
	cmp #DirUp
	bne @CheckDown
	A16
	lda TempY
	sec
	sbc #$21                  ; 33 rows up
	and #$00ff                ; wrap around
	tay                       ; calling convention for passing the row
	jsr DecompressMapRow
	jsr CopyMapRowToBuffer
	bra @CheckEvent

@CheckDown:
.a8
	cmp #DirDown
	bne @CheckLeft
	A16
	lda TempY
	clc
	adc #$1e                  ; 30 rows down
	and #$00ff                ; wrap around
	tay                       ; calling convention for passing the row
	jsr DecompressMapRow
	jsr CopyMapRowToBuffer
	bra @CheckEvent

	; If we're going left or right, the map data is already loaded, we just need
	; to copy graphics into VRAM.
@CheckLeft:
.a8
	cmp #DirLeft
	bne @CheckRight
	A16
	lda TempX
	sec
	sbc #$1f                  ; 31 columns left
	and #$00ff                ; wrap around
	tax                       ; calling convention for passing the column
	jsr CopyMapColumnToBuffer
	bra @CheckEvent
@CheckRight:
.a8
	cmp #DirRight             ; theoretically, we don't need this
	bne @CheckEvent            ; or this
	A16
	lda TempX
	clc
	adc #$20                  ; 32 columns right
	and #$00ff                ; wrap around
	tax                       ; calling convention for passing the column
	jsr CopyMapColumnToBuffer
	;bra @CheckEvent

@CheckEvent:                   ; Then we check to see if we triggered an event, like entering a cave or town.
@CheckVehicle:                 ; Make sure we're in the right vehicle
	AXY8
	lda CURR_VEHICLE
	cmp #Vehicle_Airship      ; if we're in the airship, we don't need to adjust our sprite
	beq @CheckEncounter
	A16
	lda CHARACTER_POS         ; we want to know about the tile we landed on
	jsr GetTileProperties
	sta TempTileProp
	and #OWTP_NoCanoe          ; did we land on a river?
	bne @CheckOcean
	ldy #Vehicle_Canoe
	sty CURR_VEHICLE
	bra @CheckEncounter
@CheckOcean:
	lda TempTileProp          ; are we in the ocean?
	and #OWTP_NoShip
	bne @CheckEncounter
	ldy #Vehicle_Ship
	sty CURR_VEHICLE

@CheckEncounter:               ; Finally, check for an enemy encounter.
	rts
.endproc

.proc SetOverworldCharacterObj
	; We need to calculate the animation frame to use here.
	; There's a sprite facing each of the four directions, and two
	; frames of animation for each.  12 character classes, ship, airship,
	; and canoe.
	Temp        = $00
	TempPalette = $02
	php
	A8
	lda #$78             ; player sprite position is $78, $67
	sta CharacterSprite
	lda #$67
	sta CharacterSprite + 1

	; Basic formula is $20*class + $4*(FACEDIR-1) + $2*animation
	; where class is 0-11, FACEDIR is as used, and animation is 0 or 1.
@CheckShip:
	lda CURR_VEHICLE
	cmp #Vehicle_Ship
	bne @CheckAirship
	lda #$04
	sta TempPalette
	lda #$0c
	bra @GetOffset
@CheckAirship:
	cmp #Vehicle_Airship
	bne @CheckCanoe
	lda #$05
	sta TempPalette
	lda #$0d
	bra @GetOffset
@CheckCanoe:
	cmp #Vehicle_Canoe
	bne @OnFoot
	lda #$06
	sta TempPalette
	lda #$0e
	bra @GetOffset
@OnFoot:
	lda CURR_CLASS
	sta TempPalette      ; use the class palette
@GetOffset:
	A16
	and #$00ff           ; we just loaded 8-bit, so mask off whatever was up there
	asl                  ; multiply by $20
	asl
	asl
	asl
	asl
	sta Temp             ; save that
	lda FACEDIR          ; get facing direction
	and #$00ff           ; facing direction is one byte
	dec                  ; facing direction is 1-based
	asl                  ; times 4
	asl
	ora Temp             ; like adding, but we know the bits don't overlap
	sta Temp
	lda MAPPOSX          ; we need to see if we should load frame 2
	and #$0008           ; see if we've walked 8 pixels, result will be 0 if we have because we're offset by 8
	bne @CheckVertical
	lda Temp
	inc                  ; get the alternate animation frame
	inc
	sta Temp
	bra @AnimationDone
@CheckVertical:
	lda MAPPOSY          ; we need to see if we should load frame 2
	and #$0008           ; see if we've walked 8 pixels, result will be 0 if we have because we're offset by 8
	bne @AnimationDone
	lda Temp
	inc                  ; get the alternate animation frame
	inc
	sta Temp
@AnimationDone:
	lda Temp                ; get the sprite
	A8
	sta CharacterSprite + 2 ; lower 8 bits of sprite tile
	xba                     ; get the high byte back
	ora #$10                ; set priority
	sta Temp                ; save that
	lda TempPalette
	asl                     ; palette bits are 1-3
	ora Temp                ; OR with the priority and high bit of sprite tile
	sta CharacterSprite + 3 ; set the sprite page bit
	lda #$01                ; reset the high bit of the x position
	trb CharacterSpriteH
	plp
	rts
.endproc

.proc SetOverworldVehicleObj
	; We're going to display the ship and airship sprites.
	TempX       = $00
	TempY       = $02
	TempVehicle = $04
	php
	A16
	lda #Vehicle_Airship
	sta TempVehicle   ; Tell the next function we are asking about the airship
	lda AIRSHIP_POS
	jsr CalculateVehicleScreenPosition
	A8
	lda TempX
	sta AirshipSprite
	lda TempY
	sta AirshipSprite + 1
	lda #$a8
	sta AirshipSprite + 2
	lda #$1b
	sta AirshipSprite + 3
	lda TempX + 1     ; do the high bit of the X position
	beq @ResetAirshipSpriteH
	lda #$04
	tsb AirshipSpriteH
	bra @Ship
@ResetAirshipSpriteH:
	lda #$04
	trb AirshipSpriteH
@Ship:
	A16
	lda #Vehicle_Ship
	sta TempVehicle   ; Tell the next function we are asking about the ship
	lda SHIP_POS
	jsr CalculateVehicleScreenPosition
	A8
	lda TempX
	sta ShipSprite
	lda TempY
	sta ShipSprite + 1
	lda #$88
	sta ShipSprite + 2
	lda #$19
	sta ShipSprite + 3
	lda TempX + 1     ; do the high bit of the X position
	beq @ResetShipSpriteH
	lda #$10
	tsb ShipSpriteH
	bra @Done
@ResetShipSpriteH:
	lda #$10
	trb ShipSpriteH
@Done:
	plp
	rts
.endproc

.proc CalculateVehicleScreenPosition
	; If the ship is at coordinates $0yy0, $0xx0 in pixel space, and the player
	; is at $0YYV, $0XXH, then the ship sprite goes at:
	; $0yy0 - $0YYV + $70, $0xx0 - $0XXH + $80
	TempX       = $00
	TempY       = $02
	TempVehicle = $04
	TempCoords  = $06
.a16
	sta TempCoords    ; save the coords
	lda CURR_VEHICLE
	and #$00ff        ; current vehicle is just one byte
	cmp TempVehicle   ; see if the vehicle we're calculating for is the one we're currently in
	beq @Hide         ; if so, hide it because the active player sprite is this vehicle
	lda TempCoords
	and #$ff00        ; do the Y coordinate first
	lsr
	lsr
	lsr
	lsr               ; shift it over to pixel space
	sec
	sbc MAPPOSY       ; subtract the player's Y coordinate
	clc
	adc #$006f        ; add the screen offset
	cmp #$fff0        ; see if it's on the top edge of the screen
	bcs @DontHideY
	cmp #$00df        ; see if it's above the bottom of the screen
	bcc @DontHideY
	bra @Hide
@DontHideY:
	sta TempY
	lda TempCoords    ; load the coords again for the X coordinate
	and #$00ff        ; low byte this time
	asl
	asl
	asl
	asl               ; and we shift left to get it in pixel space
	sec
	sbc MAPPOSX       ; subtract player X
	clc
	adc #$0080        ; add the screen offset
	cmp #$fff1        ; see if it's on the left edge of the screen
	bcs @DontHideX
	cmp #$0100        ; see if it's before the right of the screen
	bcc @DontHideX
	bra @Hide
@DontHideX:
	sta TempX
	rts
@Hide:
	lda #$0100        ; sprite coords $00, $100 are off screen
	sta TempX
	stz TempY
	rts
.endproc

.proc TakeoffAirship
	ldx #Vehicle_Airship
	stx CURR_VEHICLE
	jsr SetOverworldCharacterObj
	jsr SetOverworldVehicleObj
@Loop:
	wai
	lda AIRSHIP_TRANSITION
	inc
	inc
	sta AIRSHIP_TRANSITION
	cmp #$80
	bne @Loop

	rts
.endproc

.proc LandAirship
@Loop:
	wai
	lda AIRSHIP_TRANSITION
	dec
	dec
	sta AIRSHIP_TRANSITION
	bne @Loop

	ldx #Vehicle_Foot
	stx CURR_VEHICLE
	lda CHARACTER_POS
	sta AIRSHIP_POS
	rts
.endproc

.proc SetupAirshipMode7HDMA
	A16
	ldx AIRSHIP_TRANSITION
	beq @Quit
	dex
	dex
	lda AirshipMode7Tables, X     ; this is a long read
	sta DMA6ADDAL                 ; we'll read from the airship mode 7 HDMA table
	sta DMA7ADDAL                 ; for both channels
	A8
	XY16
	stz HDMAEN                    ; reset HDMA
	lda #<M7A                     ; write to M7A
	sta DMA6ADDB                  ; on channel 6
	lda #<M7D                     ; and M7D
	sta DMA7ADDB                  ; on channel 7
	lda #BANK_AIRSHIPM7           ; which is in this bank
	sta DMA6ADDAH
	sta DMA7ADDAH
	lda #$02                      ; configure HDMA for A->B, 2 bytes to 1 register (M7A/M7D)
	sta DMA6PARAM
	sta DMA7PARAM
	lda #$C0                      ; channels 6 and 7
	sta HDMAEN                    ; enable
	rts
@Quit:
	A8
	stz HDMAEN                    ; just zero this out
	rts
.endproc

.proc SetMode7Matrix
	A8
	lda #BANK_MAIN    ; set data bank to main (where the trig tables are)
	pha
	plb

	lda MAPPOSX
	sta M7X
	lda MAPPOSX + 1
	sta M7X
	lda MAPPOSY
	sta M7Y
	lda MAPPOSY + 1
	sta M7Y

	TempX = $00
	TempY = $02
	A16
	lda MAPPOSX
	sec
	sbc #$80
	sta TempX
	lda MAPPOSY
	sec
	sbc #$70
	sta TempY

	A8
	lda TempX
	sta BG1HOFS
	lda TempX + 1
	sta BG1HOFS
	lda TempY
	sta BG1VOFS
	lda TempY + 1
	sta BG1VOFS

	; Now we do trig.
	TempCos    = $02
	TempSin    = $04
	TempNegSin = $06
	A16
	lda MAPANGLE
	jsr Cosine        ; get the cosine
	sta TempCos
	A8
    lda TempCos       ; multiply -- this will be signed, fixed-point where A is IIII IIII.FFFF FFFF
	sta M7A           ; and B is II.FF FFFF
	lda TempCos + 1
	sta M7A
	lda MAPZOOM
	sta M7B
	lda MPYL          ; we need the result shifted down six times, but it's 24-bit, and we only need
	asl               ; 16 bits of it, so we can shift it up twice and take the two high bytes
	sta TempCos
	lda MPYM
	rol
	sta TempCos + 1
	lda MPYH
	rol
	sta TempCos + 2   ; this will overwrite, but if we do it in the right order, doesn't matter
	lda TempCos
	asl
	lda TempCos + 1
	rol
	sta TempCos
	lda TempCos + 2
	rol
	sta TempCos + 1

	A16
	lda MAPANGLE
	jsr Sine          ; get the sine
	sta TempSin
	A8
    lda TempSin       ; multiply -- this will be signed, fixed-point where A is IIII IIII.FFFF FFFF
	sta M7A           ; and B is II.FF FFFF
	lda TempSin + 1
	sta M7A
	lda MAPZOOM
	sta M7B
	lda MPYL          ; we need the result shifted down six times, but it's 24-bit, and we only need
	asl               ; 16 bits of it, so we can shift it up twice and take the two high bytes
	sta TempSin
	lda MPYM
	rol
	sta TempSin + 1
	lda MPYH
	rol
	sta TempSin + 2   ; this will overwrite, but if we do it in the right order, doesn't matter
	lda TempSin
	asl
	lda TempSin + 1
	rol
	sta TempSin
	lda TempSin + 2
	rol
	sta TempSin + 1

	A16
	lda TempSin       ; get the negative sine
	eor #$FFFF
	inc
	sta TempNegSin

	; Now we've done the trig calculations, set up the matrix.
	XY16
	sep #$20
	lda TempCos
	sta M7A
	lda TempCos + 1
	sta M7A
	lda TempNegSin
	sta M7B
	lda TempNegSin + 1
	sta M7B
	lda TempSin
	sta M7C
	lda TempSin + 1
	sta M7C
	lda TempCos
	sta M7D
	lda TempCos + 1
	sta M7D

	rts
.endproc
