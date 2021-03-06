#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_lseek.S.LIBGLOSS)
	.global		_lseek
_lseek:
	ENTER_BX_(8)
	MOV_ARG2W_BX_(%dx)
	MOV_ARG4W_BX_(%cx)
#ifndef __IA16_CALLCVT_REGPARMCALL
	MOV_ARG6B_BX_(%al)
	MOV_ARG0W_BX_(%bx)
#else
	MOV_ARG6B_BX_(%bl)
	xchg	%ax,	%bx
#endif
	movb	$0x42,	%ah
	int	$0x21
	jnc	.noerror
	movw	%ax,	errno
	movw	$-1,	%ax
	cwd
.noerror:
	RET_(8)
