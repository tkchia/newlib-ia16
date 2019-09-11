#include "call-cvt.h"
#include "pmode.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_mkdir.S.LIBGLOSS)
	.global		_mkdir
_mkdir:
	ENTER_BX_(4)
	MOV_ARG0W_BX_(%dx)
	movb	$0x39,	%ah
	RMODE_DOS_CALL_
	jc	.error
	xorw	%ax,	%ax
	RET_(4)
.error:
	movw	%ax,	errno
	movw	$-1,	%ax
	RET_(4)
