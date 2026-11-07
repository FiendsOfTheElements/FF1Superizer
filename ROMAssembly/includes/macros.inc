; Register bitness macros
.macro A8
	sep #$20
.endmacro
.macro A16
	rep #$20
.endmacro
.macro XY8
	sep #$10
.endmacro
.macro XY16
	rep #$10
.endmacro
.macro AXY8
	sep #$30
.endmacro
.macro AXY16
	rep #$30
.endmacro

; COLOR
;
; Given three integers ranging from 0 to 31, outputs a 16-bit value representing
; the equivalent SNES color value.
.macro COLOR r, g, b
    .word (b << 10) + (g << 5) + r
.endmacro

; CALL, LONGCALL
;
; This calls a function by pushing arguments onto the stack.  The function must
; expect the arguments to be on the stack, each argument is a two-byte constant.
; X,Y must be 16-bit, as this will pop the arguments after the function call.
.macro CALL func, p1, p2, p3, p4, p5, p6, p7, p8
	pea p1
.ifnblank p2
	CALL func, p2, p3, p4, p5, p6, p7, p8
.else
	jsr func
.endif
	plx
.endmacro

.macro LONGCALL func, p1, p2, p3, p4, p5, p6, p7, p8
	pea p1
.ifnblank p2
	LONGCALL func, p2, p3, p4, p5, p6, p7, p8
.else
	jsl func
.endif
	plx
.endmacro
