#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (strcmp.S.NEWLIB)
	.global		strcmp
strcmp:
	ENTER_BX_(4)
	pushw	%si
	MOV_ARG0W_BX_(%si)
	MOV_ARG2W_BX_(%bx)
	decw	%bx
.L1:
	lodsb
	incw	%bx
	testb	%al,	%al
	jz	.L2
	cmpb	(%bx),	%al
	je	.L1
.L2:
	movb	(%bx),	%dl
	xorb	%dh,	%dh
	xorb	%ah,	%ah
	subw	%dx,	%ax
	popw	%si
	RET_(4)
