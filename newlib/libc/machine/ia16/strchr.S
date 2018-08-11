#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		strchr
strchr:
	ENTER_BX_
	pushw	%si
	MOV_ARG0W_BX_(%si)
	MOV_ARG2B_BX_(%ah)
.L1:
	lodsb
	cmp	%al,	%ah
	jz	.L2
	testb	%al,	%al
	jnz	.L1

	xorw	%ax,	%ax
	popw	%si
	RET_(4)
.L2:
	movw	%si,	%ax
	decw	%ax
	popw	%si
	RET_(4)
