/*
 * Implementation of _times_r for DOS which should be relatively fast, if a
 * tad hacky.
 *
 * To avoid having to deal with discontinuities in the system timer --- due
 * to midnight crossover, daylight saving time, and what not --- I arrange
 * to install our own timer tick ISR (int $0x1c) which increments its own
 * separate counters.  The ISR is placed in the data segment (!) to make it
 * easier to access its own data, unless our program is a DPMI-mode program.
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

	TEXT_ (dos_timesr.S.LIBGLOSS)
	.section .text, "ax"

.Lctor_timesr:
#ifndef __IA16_FEATURE_DOSX
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
#else
	pushw	%es
	pushw	%di
	pushw	%ds
	popw	%es
	xorw	%cx,	%cx
	pushw	%cx
	pushw	%cx
	subw	$0x32-4, %sp
	movw	%sp,	%di
	movb	$0x34,	0x1d(%di)
	mov	$0x0300, %ax
	movw	$0x0021, %bx
	int	$0x31
	movw	0x10(%di), %ax
	movw	%ax,	.Lp_indos
	movw	0x22(%di), %bx
	addw	$0x32, %sp
	popw	%di
	popw	%es
	movw	$0x0002, %ax
	int	$0x31
	movw	%ax,	.Lp_indos+2
	movw	$0x0204, %ax
	movb	$0x1c,	%bl
	int	$0x31
	/*
	 * FIXME: this currently assumes that the original int $0x1c vector
	 * offset fits into 16 bits.
	 */
	movw	%dx,	.Lp_orig_int_0x1c
	movw	%cx,	.Lp_orig_int_0x1c+2
	incw	%ax
	movw	$.Lour_int_0x1c, %dx
	movw	%cs,	%cx
	callw	*__dosx_dpmi16_shim
	RET_ (0)
#endif

.Ldtor_timesr:
#ifndef __IA16_FEATURE_DOSX
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
#else
	movw	$0x0204, %ax
	mov	$0x1c,	%bl
	int	$0x31
	cmp	$.Lour_int_0x1c, %dx
	jnz	0f
	movw	%ds,	%dx
	cmpw	%dx,	%cx
	jnz	0f
	movw	.Lp_orig_int_0x1c, %dx
	movw	.Lp_orig_int_0x1c+2, %cx
	incw	%ax
	int	$0x31
0:	RET_ (0)
#endif

	.global	_times_r
_times_r:
	ENTER_BX_(4)
	MOV_ARG2W_BX_(%bx)
#ifndef __IA16_FEATURE_DOSX
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
	RET_(4)

	.section .data, "aw"

.Luser_counter:
	.hword	-19663, 0, 0
.Lsystem_counter:
	.hword	-19663, 0, 0

#ifdef __IA16_FEATURE_DOSX
	.section .text, "ax"
#endif

.Lour_int_0x1c:
	pushw	%ax
	pushw	%ax
	pushfw
	pushw	%ds
	pushw	%es
	pushw	%ax
	pushw	%bx
#ifndef __IA16_FEATURE_DOSX
	movw	%cs,	%bx
	movw	%bx,	%ds
#else
	movw	%cs:__ia16_near_data_segment, %ds
#endif
	movw	%sp,	%bx
	movw	.Lp_orig_int_0x1c, %ax
	movw	%ax,	%ss:10(%bx)
	movw	.Lp_orig_int_0x1c+2, %ax
	movw	%ax,	%ss:12(%bx)
	lesw	.Lp_indos, %bx
	cmpb	$0,	%es:(%bx)
	movw	$.Luser_counter, %bx
	jnz	2f
0:	addw	$(_CLOCKS_PER_SEC_ * 1080 % 19663), (%bx)
	jnc	1f
	subw	$19663,	(%bx)	/* this sets the carry flag */
1:	adcw	$(_CLOCKS_PER_SEC_ * 1080 / 19663), 2(%bx)
	adcw	$(_CLOCKS_PER_SEC_ * 1080 / 19663) >> 16, 4(%bx)
	popw	%bx
	popw	%ax
	popw	%es
	popw	%ds
	popfw
	lretw
2:	movw	$.Lsystem_counter, %bx
	jmp	0b

	.balign	2

	.section .ctors.65534

	.balign	2
	TEXT_PTR_ (.Lctor_timesr)

	.section .dtors.65534

	.balign	2
	TEXT_PTR_ (.Ldtor_timesr)

	.lcomm	.Lp_orig_int_0x1c, 4
	.lcomm	.Lp_indos, 4
