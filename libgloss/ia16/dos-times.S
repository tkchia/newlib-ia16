/*
 * Implementation of _times for DOS which should be relatively fast, if a
 * tad hacky.
 *
 * To avoid having to deal with discontinuities in the system timer --- due
 * to midnight crossover, daylight saving time, and what not --- I arrange
 * to install our own timer tick ISR (int $0x1c) which increments its own
 * separate counters.  The ISR is placed in the data segment (!) to make it
 * easier to access its own data.  (These hacks, of course, only work
 * properly in real mode or V86 mode...)
 *
 * Each int 0x1c call corresponds to (24 * 60 * 60) / 0x1800b0 == 1080 / 19663
 * seconds of elapsed time, so it should increment the number of clock_t
 * "ticks" by _CLOCKS_PER_SEC_ * 1080 / 19663.  The code maintains the
 * fractional portion of the "tick" count in a separate halfword.
 *
 * I also use the DOS 2+ InDOS flag to get a (crude) indication of whether
 * the CPU is running "system" code or "user" code at each point in time.
 */

#include <machine/time.h>
#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

#APP /* need this to expand _CLOCKS_PER_SEC_ properly */
#ifndef _CLOCKS_PER_SEC_
#define _CLOCKS_PER_SEC_ 1000
#endif

	TEXT_ (dos_times.S.LIBGLOSS)
	.section .text

.Lctor_times:
#ifdef __IA16_FEATURE_PROTECTED_MODE
	movw	$0f,	%bx
	jmp	__ia16_rmode_func_call_bx
0:
#endif
	pushw	%es
	movb	$0x34,	%ah
	int	$0x21
	movw	%bx,	.Lp_indos
	movw	%es,	.Lp_indos+2
	movw	$0x351c, %ax
	int	$0x21
	movw	%bx,	.Lp_orig_int_0x1c
	movw	%es,	.Lp_orig_int_0x1c+2
	movw	$0x251c, %ax
	movw	$.Lour_int_0x1c, %dx
	int	$0x21
	popw	%es
	RET_ (0)

.Ldtor_times:
#ifdef __IA16_FEATURE_PROTECTED_MODE
	movw	$0f,	%bx
	jmp	__ia16_rmode_func_call_bx
0:
#endif
	pushw	%es
	/*
	 * If the program (or some other program) had also added its own
	 * hook for int $0x1c, then do nothing.  Otherwise, undo our hook.
	 */
	movw	$0x351c, %ax
	int	$0x21
	cmp	$.Lour_int_0x1c, %bx
	jnz	0f
	movw	%es,	%ax
	movw	%ds,	%dx
	cmpw	%ax,	%dx
	jnz	0f
	pushw	%ds
	ldsw	.Lp_orig_int_0x1c, %dx
	movw	$0x251c, %ax
	int	$0x21
	popw	%ds
0:	popw	%es
	RET_ (0)

	.global	_times
_times:
	ENTER_BX_(2)
	MOV_ARG0W_BX_(%bx)
#ifndef __IA16_FEATURE_PROTECTED_MODE
	movw	%es,	%cx
	/* Fill ->tms_utime.  */
	lesw	.Luser_counter+2, %dx
	movw	%dx,	(%bx)
	movw	%es,	2(%bx)
	/* Fill ->tms_stime.  */
	lesw	.Lsystem_counter+2, %ax
	movw	%ax,	4(%bx)
	movw	%es,	6(%bx)
	movw	%cx,	%es
#else
	cli
	/* Fill ->tms_utime.  */
	movw	.Luser_counter+2, %dx
	movw	.Luser_counter+4, %cx
	movw	%dx,	(%bx)
	movw	%cx,	2(%bx)
	/* Fill ->tms_stime.  */
	movw	.Lsystem_counter+2, %ax
	movw	.Lsystem_counter+4, %cx
	movw	%ax,	4(%bx)
	movw	%cx,	6(%bx)
	sti
#endif
	/* Zero ->tms_cutime and ->tms_cstime for now...  */
	xorw	%cx,	%cx
	movw	%cx,	8(%bx)
	movw	%cx,	10(%bx)
	movw	%cx,	12(%bx)
	movw	%cx,	14(%bx)
	/* Add up ->tms_utime and ->tms_stime for the return value.  */
	addw	%dx,	%ax
	movw	6(%bx),	%dx
	adcw	2(%bx),	%dx
	RET_(2)

	.section .data

.Luser_counter:
	.hword	-19663, 0, 0
.Lsystem_counter:
	.hword	-19663, 0, 0

.Lour_int_0x1c:
	pushfw
	pushw	%ds
	pushw	%bx
	ldsw	%cs:.Lp_indos, %bx
	cmpb	$0,	(%bx)
	movw	$.Luser_counter, %bx
	jnz	2f
0:	addw	$(_CLOCKS_PER_SEC_ * 1080 % 19663), %cs:(%bx)
	jnc	1f
	subw	$19663,	%cs:(%bx)	/* this sets the carry flag */
1:	adcw	$(_CLOCKS_PER_SEC_ * 1080 / 19663), %cs:2(%bx)
	adcw	$(_CLOCKS_PER_SEC_ * 1080 / 19663) >> 16, %cs:4(%bx)
	popw	%bx
	popw	%ds
	popfw
	ljmpw	*%cs:.Lp_orig_int_0x1c
2:	movw	$.Lsystem_counter, %bx
	jmp	0b

	.balign	2

	.section .ctors.65535

	.balign	2
	TEXT_PTR_ (.Lctor_times)

	.section .dtors.65535

	.balign	2
	TEXT_PTR_ (.Ldtor_times)

	.lcomm	.Lp_orig_int_0x1c, 4
	.lcomm	.Lp_indos, 4
