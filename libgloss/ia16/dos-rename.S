#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		_rename
_rename:
	ENTER_BX_
	pushw	%es
	pushw	%di
	movw	%ds,	%di
	movw	%di,	%es
	MOV_ARG2W_BX_(%di)
	MOV_ARG0W_BX_(%dx)
	movb	$0x56,	%ah
	int	$0x21
	jc	.error
	xorw	%ax,	%ax
	popw	%di
	popw	%es
	RET_(4)
.error:
	movw	%ax,	errno
	movw	$-1,	%ax
	popw	%di
	popw	%es
	RET_(4)
