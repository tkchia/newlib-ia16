#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		_mkdir
_mkdir:
	ENTER_BX_
	MOV_ARG0W_BX_(%dx)
	movb	$0x39,	%ah
	int	$0x21
	jc	.error
	xorw	%ax,	%ax
	RET_(4)
.error:
	movw	%ax,	errno
	movw	$-1,	%ax
	RET_(4)
