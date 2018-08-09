#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		_read
_read:
	ENTER_BX_
	MOV_ARG2W_BX_(%dx)
	MOV_ARG4W_BX_(%cx)
	MOV_ARG0W_BX_(%bx)
	movb	$0x3f,	%ah
	int	$0x21
	jnc	.noerror
	movw	%ax,	errno
	movw	$-1,	%ax
.noerror:
	RET_(6)
