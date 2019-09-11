#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (memccpy.S.NEWLIB)
	.global		memccpy
memccpy:
	ENTER_BX_(8)
	pushw	%si
	pushw	%di
	pushw	%es
	movw	%ds,	%si
	movw	%si,	%es
	MOV_ARG0W_BX_(%di)
	MOV_ARG2W_BX_(%si)
	MOV_ARG4B_BX_(%ah)
	MOV_ARG6W_BX_(%cx)
	jcxz	.L2
.L1:
	lodsb
	stosb
	cmpb	%al,	%ah
	loopne	.L1
	jne	.L2
	movw	%di,	%ax
	decw	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(8)
.L2:
	xorw	%ax,	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(8)
