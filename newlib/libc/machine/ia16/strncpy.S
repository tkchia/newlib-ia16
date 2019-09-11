#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (strncpy.S.NEWLIB)
	.global		strncpy
strncpy:
	ENTER_BX_(6)
	pushw	%si
	pushw	%di
	pushw	%es
	MOV_ARG0W_BX_(%di)
	MOV_ARG2W_BX_(%si)
	MOV_ARG4W_BX_(%cx)
	movw	%ds,	%ax
	movw	%ax,	%es
	movw	%di,	%bx
	jcxz	.L2
.L1:
	lodsb
	stosb
	testb	%al,	%al
	loopnz	.L1

	xorw	%ax,	%ax
	shrw	$1,	%cx
	rep	stosw
	adcw	%cx,	%cx
	rep	stosb
.L2:
	movw	%bx,	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
