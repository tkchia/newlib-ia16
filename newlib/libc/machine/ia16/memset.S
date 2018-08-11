#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		memset
memset:
	ENTER_BX_
	pushw	%di
	pushw	%es
	movw	%ds,	%di
	movw	%di,	%es
	MOV_ARG0W_BX_(%di)
	MOV_ARG2B_BX_(%al)
	MOV_ARG4W_BX_(%cx)
	movw	%di,	%bx
	movb	%al,	%ah
	shrw	$1,	%cx
	rep	stosw
	adcw	%cx,	%cx
	rep	stosb
	movw	%bx,	%ax
	popw	%es
	popw	%di
	RET_(6)
