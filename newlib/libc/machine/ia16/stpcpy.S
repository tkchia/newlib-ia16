#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (stpcpy.S.NEWLIB)
	.global		stpcpy
stpcpy:
	ENTER_BX_(4)
	pushw	%si
	pushw	%di
	pushw	%es
	MOV_ARG0W_BX_(%di)
	MOV_ARG2W_BX_(%si)
	movw	%ds,	%ax
	movw	%ax,	%es
.L1:
	lodsb
	stosb
	testb	%al,	%al
	jnz	.L1

	movw	%di,	%ax
	decw	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(4)
