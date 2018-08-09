# setjmp/longjmp for ia16.  The jmpbuf looks like this:
#	
# Register	jmpbuf offset
# ax		0x00
# bx		0x02
# cx		0x04
# dx		0x06
# si		0x08
# di		0x0a
# bp		0x0c
# sp		0x0e
# es		0x10
# ip            0x12
	
#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

#ifdef __ELKS__
	.text
	.global		_setjmp
_setjmp:
#else
	.section	".text"
	.global		setjmp
setjmp:
#endif
#		%ip		# 4(%bp)
	pushw	%bx		# 2(%bp)
	pushw	%bp		# 0(%bp)
	movw	%sp,	%bp
#ifndef __IA16_CALLCVT_REGPARMCALL
	movw	6(%bp),	%bx	# %bx points to jumpbuf.
#else
	movw	%ax,	%bx
#endif
	movw	%ax,	(%bx)	# Save %ax.
	movw	2(%bp),	%ax
	movw	%ax,	2(%bx)	# Save %bx.
	movw	%cx,	4(%bx)	# Save %cx.
	movw	%dx,	6(%bx)	# Save %dx.
	movw	%si,	8(%bx)	# Save %si.
	movw	%di,	10(%bx)	# Save %di.
	movw	0(%bp),	%ax
	movw	%ax,	12(%bx)	# Save %bp.
	leaw	6(%bp),	%ax
	movw	%ax,	14(%bx)	# Save %sp.
	movw	4(%bp),	%ax
	movw	%es,	16(%bx)	# Save %es.
	movw	%ax,	18(%bx)	# Save %ip.

# Return 0 to caller.
	xorw	%ax,	%ax
	popw	%bp
	popw	%bx
	RET_(2)

#ifdef __ELKS__
	.global _longjmp
_longjmp:
#else
	.global	longjmp
longjmp:
#endif
	movw	%sp,	%bp
#ifndef __IA16_CALLCVT_REGPARMCALL
	movw	4(%bp),	%ax	# Get retval.
	movw	2(%bp),	%bp	# Get jmpbuf.
#else
	movw	%ax,	%bp
	movw	%dx,	%ax
#endif
	movw	%ax,	0(%bp)	# Store retval in jmpbuf[0].

	lesw	14(%bp),%sp	# Restore %sp and %es.
	pushw	18(%bp)		# Restore %ip.
	movw	10(%bp),%di	# Restore %di.
	movw	8(%bp),	%si	# Restore %si.
	movw	6(%bp),	%dx	# Restore %dx.
	movw	4(%bp),	%cx	# Restore %cx.
	movw	2(%bp),	%bx	# Restore %bx.
	movw	0(%bp),	%ax	# Restore %ax.
	movw	12(%bp),%bp	# Restore %bp.	

# If caller attempted to return 0, return 1 instead.

	cmpw	$1,	%ax
	adcw	$0,	%ax
	RET_(2)
