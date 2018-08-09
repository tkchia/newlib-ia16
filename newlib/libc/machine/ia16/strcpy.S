#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		strcpy
strcpy:
	ENTER_BX_
	pushw	%si
	pushw	%di
	pushw	%es
	MOV_ARG0W_BX_(%di)
	MOV_ARG2W_BX_(%si)
	movw	%ds,	%ax
	movw	%ax,	%es
	movw	%di,	%bx
.L1:
	lodsb
	stosb
	testb	%al,	%al
	jnz	.L1

	movw	%bx,	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(4)
