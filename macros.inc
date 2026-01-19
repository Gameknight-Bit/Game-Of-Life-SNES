;------------------
; Collection of Useful WLA-65816 Macros for SNES Use
; Compiled by: Jace Parks
;------------------

;Macros for Register 8-bit vs 16-bit modes
.16bit

.macro A8
	sep #$20
.endm

.macro A16
	rep #$20
.endm

.macro AXY8
	sep #$30
.endm

.macro AXY16
	rep #$30
.endm

.macro XY8
	sep #$10
.endm

.macro XY16
	rep #$10
.endm