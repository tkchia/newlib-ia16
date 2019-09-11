#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_isatty.S.LIBGLOSS)
	.global		_isatty
_isatty:
	ENTER_BX_(2)
	MOV_ARG0W_BX_(%bx)
	movw	$0x4400,	%ax
	int	$0x21
	jc	.error
	movw	$0x112,	%ax	# ENOTTY
	testb	$0x80,	%dl
	jz	.error
	movw	$1,	%ax
	RET_(2)
.error:
	movw	%ax,	errno
	xorw	%ax,	%ax
	RET_(2)
