#include "call-cvt.h"
#include "pmode.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (dos_write.S.LIBGLOSS)
	.global		_write
_write:
	ENTER_BX_(6)
	MOV_ARG4W_BX_(%cx)
	/*
	 * int $0x21 with %ah == 0x40 and %cx == 0 will truncate or extend
	 * the file to the current position (www.ctyme.com/intr/rb-2791.htm).
	 *
	 * This differs from POSIX semantics for write (fd, buf, 0), which
	 * say that the function should only detect errors or do nothing.
	 *
	 * Thus we need to check for the write (fd, buf, 0) case, and treat
	 * it specially.
	 */
	jcxz	.nowrite
	MOV_ARG2W_BX_(%dx)
	MOV_ARG0W_BX_(%bx)
	movb	$0x40,	%ah
	RMODE_DOS_CALL_
	jnc	.noerror
	movw	%ax,	errno
	sbbw	%cx,	%cx
.nowrite:
	xchgw	%ax,	%cx
.noerror:
	RET_(6)
