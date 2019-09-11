#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_close.S.LIBGLOSS)
	.global		_close
_close:
	ENTER_BX_(2)
	MOV_ARG0W_BX_(%bx)
	movb	$0x3e,	%ah
	int	$0x21
	jc	.error
	xorw	%ax,	%ax
	RET_(2)
.error:
	movw	%ax,	errno
	movw	$-1,	%ax
	RET_(2)
