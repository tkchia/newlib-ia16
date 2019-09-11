#include "call-cvt.h"
#include "pmode.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_read.S.LIBGLOSS)
	.global		_read
_read:
	ENTER_BX_(6)
	MOV_ARG2W_BX_(%dx)
	MOV_ARG4W_BX_(%cx)
	MOV_ARG0W_BX_(%bx)
	movb	$0x3f,	%ah
	RMODE_DOS_CALL_
	jnc	.noerror
	movw	%ax,	errno
	movw	$-1,	%ax
.noerror:
	RET_(6)
