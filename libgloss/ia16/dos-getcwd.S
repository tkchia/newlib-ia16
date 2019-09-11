#include "call-cvt.h"
#include "pmode.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_getcwd.S.LIBGLOSS)
	.global		_getcwd
_getcwd:
	ENTER_BX_(4)
	pushw	%si
	cmpw	$64,	ARG2W_BX_
	movw	$0x101,	%ax  # ERANGE
	jl	.error
	MOV_ARG0W_BX_(%si)
	movb	$0,	%dl
	movb	$0x47,	%ah
	RMODE_DOS_CALL_
	jc	.error
	movw	%si,	%ax
	popw	%si
	RET_(4)
.error:
	movw	%ax,	errno
	movw	$-1,	%ax
	popw	%si
	RET_(4)
