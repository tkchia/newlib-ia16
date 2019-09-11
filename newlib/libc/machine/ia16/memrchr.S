#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (memrchr.S.NEWLIB)
	.global		memrchr
memrchr:
	ENTER_BX_(6)
	pushw	%di
	pushw	%es
	movw	%ds,	%di
	movw	%di,	%es
	MOV_ARG0W_BX_(%di)
	MOV_ARG2B_BX_(%al)
	MOV_ARG4W_BX_(%cx)
	addw	%cx,	%di
	decw	%di
	std
	repne	scasb
	cld
	je	.L1
	xorw	%ax,	%ax
	popw	%es
	popw	%di
	RET_(6)
.L1:
	movw	%di,	%ax
	incw	%ax
	popw	%es
	popw	%di
	RET_(6)
