#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_dup.S.LIBGLOSS)
	.global		dup
dup:
	ENTER_BX_(2)
	MOV_ARG0W_BX_(%bx)
	movb	$0x45,	%ah
	int	$0x21
	jnc	.noerror
	movw	%ax,	errno
	sbbw	%ax,	%ax
.noerror:
	RET_(2)
