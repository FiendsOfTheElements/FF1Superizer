.p816
.a8
.i16

.export GetJoypadInputs

.include "registers.inc"
.include "defines.inc"
.include "macros.inc"

.segment "CODE"

.proc GetJoypadInputs
	php

	A8
	lda HVBJOY                          ; get joypad status
	and #$01                            ; check whether joypad done reading...
	bne GetJoypadInputs                 ; ...if not, wait a bit more

	; first, check for newly pressed buttons since last frame
	AXY16
	lda JOY1L                           ; get new input from this frame
	ldy JoyPad1                         ; get input from last frame
	sta JoyPad1                         ; store new input from this frame
	tya                                 ; check for newly pressed buttons...
	eor JoyPad1                         ; filter buttons that were not pressed last frame
	and JoyPad1                         ; filter held buttons from last frame
	sta JoyTrigger1                     ; ...and store them
	; second, check for buttons held from last frame
	tya                                 ; get input from last frame
	and JoyPad1                         ; filter held buttons from last frame...
	sta JoyHeld1                        ; ...store them

	plp
	rts
.endproc
