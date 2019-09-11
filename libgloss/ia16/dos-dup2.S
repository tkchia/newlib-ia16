#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_dup2.S.LIBGLOSS)
	.global		dup2
dup2:
	ENTER_BX_(4)
	MOV_ARG2W_BX_(%cx)
	MOV_ARG0W_BX_(%bx)
	movb	$0x46,	%ah
	int	$0x21
	jnc	.noerror
	movw	%ax,	errno
	sbbw	%cx,	%cx
.noerror:
	movw	%cx,	%ax
	RET_(4)
