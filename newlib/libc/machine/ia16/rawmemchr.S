#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (rawmemchr.S.NEWLIB)
	.global		rawmemchr
rawmemchr:
	ENTER_BX_(4)
	pushw	%di
	pushw	%es
	movw	%ds,	%di
	movw	%di,	%es
	MOV_ARG0W_BX_(%di)
	MOV_ARG2B_BX_(%al)
	movw	$-1,	%cx
	repne	scasb
	movw	%di,	%ax
	decw	%ax
	popw	%es
	popw	%di
	RET_(4)
