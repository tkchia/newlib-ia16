#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		_lseek
_lseek:
#ifndef __IA16_CALLCVT_REGPARMCALL
	movw	%sp,	%bx
	movw	4(%bx),	%dx
	movw	6(%bx),	%cx
	movb	8(%bx),	%al
	movw	2(%bx),	%bx
#else
	movw	%bx,	%dx
	movw	%sp,	%bx
	movb	2(%bx),	%bl
	xchg	%ax,	%bx
#endif
	movb	$0x42,	%ah
	int	$0x21
	jnc	.noerror
	movw	%ax,	errno
	movw	$-1,	%ax
	cwd
.noerror:
	RET2_(8)
