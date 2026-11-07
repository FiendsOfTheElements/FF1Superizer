.p816
.a8
.i16

.segment "TITLE"
	.byte "FF1SNES             " ; 20 characters available here, do not pad with zeroes

.segment "ROMINFO"
	.byte $00 ; Use ROMINFOEX
	.byte $20 ; LoROM, SlowROM
	.byte $02 ; Battery SRAM, no co-processor
	.byte $08 ; 256K ROM (we'll increase this later)
	.byte $05 ; 32K SRAM (can increase if needed)
	.byte $01 ; North America (there doesn't seem to be a standard for "any region")
	.byte $33 ; Developer ID ($33 means use ROMINFOEX)
	.byte $00 ; Original version (1.0)
	.word $AAAA, $5555 ; Checksum (placeholder values)

.segment "ROMINFOEX"
	.byte "FE"   ; (Fiends of the Elements)
	.byte "FF1S" ; Game code
	.byte $00, $00, $00, $00, $00, $00 ; Unused
	.byte $00 ; No Flash ROM
	.byte $00 ; No Expansion RAM
	.byte $00 ; Not a special version
	.byte $00 ; No co-processor

.segment "VECTORS"
	; native mode
	;     NOT    USED   COP,   BRK,   ABT,   NMI,        RST,          IRQ
	.addr $0000, $0000, $0000, $0000, $0000, NMIHandler, $0000,        $0000

	; emulation mode
	;     NOT    USED   COP,   BRK,   ABT,   NMI,        RST,          IRQ
	.addr $0000, $0000, $0000, $0000, $0000, $0000,      ResetHandler, $0000

.import GetJoypadInputs

.import LoadTitleScreenAndWaitForInput
.import DoCharacterSelect

.import LoadOverworld
.import DoOverworldMovement
.import SetOverworldCharacterObj
.import SetOverworldVehicleObj
.import CopyTileMapBufferToVRAM
.import SetMode7Matrix
.import SetupAirshipMode7HDMA

.export CopyOamMirrorToOAM
.export CopyBG3TileMapBufferToVRAM
.export DMA2VRAML : far

.include "registers.inc"
.include "defines.inc"
.include "macros.inc"

.segment "CODE"

.proc   ResetHandler
	sei                     ; disable interrupts
	clc                     ; clear the carry flag
	xce                     ; switch the 65816 to native (16-bit mode)
	XY16
	A8

	ldx #$1fff              ; set the stack pointer to $1fff
	txs

	jsr InitializeOam
	jsr CopyOamMirrorToOAM
	jsr LoadTitleScreenAndWaitForInput

	jsr InitializeOam
	jsr CopyOamMirrorToOAM
	jsr DoCharacterSelect

	jsr InitializeOam
	jsr LoadOverworld

	jmp GameLoop            ; all initialization is done
.endproc

.proc InitializeOam
	XY16
	A8
	lda #$e0                ; this will put sprites off the bottom of the screen
	ldx #$1ff               ; size of main OAM
@BaseLoop:
	stz OamMirror, X        ; zero out main OAM
	dex
	stz OamMirror, X        ; zero out main OAM
	dex
	sta OamMirror, X        ; the Y coordinate
	dex
	stz OamMirror, X        ; zero out main OAM
	dex
	bpl @BaseLoop

	lda #$55                ; this sets the sprite size to 0 and puts the sprite off the right side of the screen
	ldx #$1f                ; size of upper OAM
@UpperLoop:
	sta OamMirror + $200, X
	dex
	bpl @UpperLoop

	rts
.endproc

.proc   GameLoop
	wai                     ; wait for NMI / V-Blank

	jsr GetJoypadInputs
	jsr DoOverworldMovement
	jsr SetOverworldCharacterObj
	jsr SetOverworldVehicleObj

	bra GameLoop
.endproc

.proc   NMIHandler
	php
	XY16
	A8

	lda RDNMI               ; read NMI status, acknowledge NMI

	jsr CopyOamMirrorToOAM

	lda GameMode
	cmp #GAME_MODE_OVERWORLD
	bne :+
	jsr CopyTileMapBufferToVRAM
	jsr SetMode7Matrix
	jsr SetupAirshipMode7HDMA
	bra :++
:
	jsr CopyBG3TileMapBufferToVRAM
:
	plp
	rti
.endproc

.proc CopyOamMirrorToOAM
	stz MDMAEN                  ; reset DMA
	ldx #$0000
	stx OAMADDL                 ; start at OAM address 0
	lda #<OAMDATA               ; write to OAM
	sta DMA7ADDB
	ldx #OamMirror              ; OamMirror is a short address
	stx DMA7ADDAL               ; read from OamMirror
	stz DMA7ADDAH               ; doesn't matter which bank
	ldx #$220                   ; write 544 bytes
	stx DMA7AMTL
	stz DMA7PARAM               ; configure DMA7 for A->B, inc A address, 1 byte to 1 register
	lda #$80                    ; enable DMA7
	sta MDMAEN
	rts
.endproc

.proc CopyBG3TileMapBufferToVRAM
	php
	XY16
	LONGCALL DMA2VRAML, 0, BG3TileMapBuffer, $3800, $0800
	plp
	rts
.endproc

.proc DMA2VRAML
; Copies data to VRAM, arguments on the stack.  This is the "normal" way
; to write to VRAM, doing a linear bulk copy.  Works for character graphics,
; tilemaps, and sprite graphics, but not for Mode 7 graphics or tilemaps.
	Bank   = $0C        ; Source bank (value only needs to be one byte)
	Source = $0A        ; Source address from memory
	Dest   = $08        ; Destination word address in VRAM
	Size   = $06        ; Size of data to transfer (bytes)

	phd
	tsc
	tcd
	php
	A8
	XY16

	lda #$80            ; VRAM increment on write to VMDATAH
	sta VMAINC
	lda #<VMDATAL       ; write to VRAM
	sta DMA7ADDB
	lda #$01            ; configuration A->B, inc A address, write 2 bytes at a time to VMDATAL/H
	sta DMA7PARAM

	lda Bank
	sta DMA7ADDAH
	ldx Source
	stx DMA7ADDAL
	ldx Dest
	stx VMADDL          ; destination address
	ldx Size
	stx DMA7AMTL

	lda #$80            ; enable DMA7
	sta MDMAEN

	plp
	pld
	rtl
.endproc
