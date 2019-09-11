#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (mempcpy.S.NEWLIB)
	.global		mempcpy
mempcpy:
	ENTER_BX_(6)
	pushw	%si
	pushw	%di
	pushw	%es
	movw	%ds,	%si
	movw	%si,	%es
	MOV_ARG0W_BX_(%di)
	MOV_ARG2W_BX_(%si)
	MOV_ARG4W_BX_(%cx)
	shrw	$1,	%cx
	rep	movsw
	adcw	%cx,	%cx
	rep	movsb
	movw	%di,	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
