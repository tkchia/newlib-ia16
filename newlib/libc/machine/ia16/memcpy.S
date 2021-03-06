#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (memcpy.S.NEWLIB)
	.global		memcpy
memcpy:
	ENTER_BX_(6)
	pushw	%si
	pushw	%di
	pushw	%es
	movw	%ds,	%si
	movw	%si,	%es
	MOV_ARG0W_BX_(%ax)
	movw	%ax,	%di
	MOV_ARG2W_BX_(%si)
	MOV_ARG4W_BX_(%cx)
	shrw	$1,	%cx
	rep	movsw
	adcw	%cx,	%cx
	rep	movsb
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
