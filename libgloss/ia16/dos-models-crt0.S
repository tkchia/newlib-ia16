/* Startup code for
     * a "tiny" model DOS .com file with combined text and data segment,
     * a "small" model DOS .exe file with one text segment and one separate
       data segment, or
     * a "medium" model DOS .exe file with multiple text segments and one
       data segment.  */

#if !defined TINY && !defined SMALL && !defined MEDIUM
#error "no memory model defined -- please use -DTINY, -DSMALL or -DMEDIUM"
#endif

#ifdef DPMIABLE
	.arch i286
#else
	.arch i8086
#endif
	.code16

#include "call-cvt.h"

	.section .startupA, "ax"
	.global _start
_start:
	# Sanity check for DOS version >= 2.  (Note that this sanity check
	# may not really work under MS-DOS 1.x, and the system may crash
	# without even coming here, unless the linker script has been set up
	# to handle 1.x, via __msdos_handle_v1.)
	mov	$0x30,	%ah
	int	$0x21
	cmp	$2,	%al
	jnb	.Ldos_ok
.Lbad:
#ifdef TINY
	ret
#else
	# Return to the `int $0x20' command at the PSP start --- we cannot
	# just say `int $0x20' here, as %cs is wrong.
	pushw	%ds
	xorw	%ax,	%ax
	pushw	%ax
	lretw
#endif
.Ldos_ok:
	# If we are building a multilib variant that assumes an 80186 CPU or
	# above, do a quick check that we are indeed dealing with a 186+.
	#
	# 0x6a is `pushw' on 186+, and an alias for 0x7a (`jpe') on the 8086
	# (www.os2museum.com/wp/undocumented-8086-opcodes/).
#ifdef __IA16_FEATURE_PUSH_IMM
	movw	%sp,	%ax
	.byte	0x6a, 0x00
	cmpw	%ax,	%sp
	jz	.Lbad
	popw	%ax
#endif
#ifndef TINY
	pushw	%ss
	popw	%es
#endif
#ifndef __IA16_FEATURE_PUSH_IMM
	# In the 80186 case, %ax is already 0.
	xorw	%ax, %ax
#endif
	movw	$__sbss, %di
	movw	$__lbss, %cx
	cld
	rep	stosw
#ifdef DPMIABLE
	# We still have segment registers pointing to the code segment, data
	# segment, and PSP; and we have not invoked the program's
	# constructor routines yet.  This is a good time to switch to
	# protected mode if we want to.
	movw	$0x1687, %ax
	int	$0x2f
	testw	%ax,	%ax
	jnz	.Lno_dpmi
	# Plug in the DPMI entry point address.  This is self-modifying code
	# (!) --- rely on the `int $0x21' later to get the instruction cache
	# flushed, before we reach the `lcallw'.
# ifdef TINY
	movw	%di,	.Ldpmi_lcall+1
	movw	%es,	.Ldpmi_lcall+3
# else
	movw	%di,	%cs:.Ldpmi_lcall+1
	movw	%es,	%cs:.Ldpmi_lcall+3
# endif
	# If we have a 32-bit DPMI host, try to see if we are running under
	# Sandmann's CWSDPMI, which works around a bug in some DPMI clients:
	#	"Ideally, on the request to enter DPMI's PM with a 16-bit
	#	 request, we would just fail the call setting the carry bit
	#	 like the DPMI specification describes.  Some buggy 16-bit
	#	 compiler tools don't check the return status and will hang
	#	 the machine in this case.  So, I issue an error message and
	#	 exit the image instead."
	# We work around this workaround, and continue in real (or V86 mode)
	# instead of quitting.
	shrw	%bx
	jnc	.L16bit_ok
	.pushsection .rodata
0:
	.byte	0xa8,0x01	#	"test	al,1"
	.byte	0x75,0x29	#	"jnz	short ok_32"
	.byte	0xba		#	"mov	dx,"...
1:
	.byte	0x0e		#	"push	cs"
	.byte	0x1f		#	"pop	ds"
	.byte	0xb4,0x09	#	"mov	ah,9"
	.byte	0xcd,0x21	#	"int	21h"
	.byte	0xb8,0x01,0x4c	#	"mov	ax,4c01h"
	.byte	0xcd,0x21	#	"int	21h"
2:
	.balign	2
	.popsection
	movw	$0b,	%si
	movw	$1b-0b,	%cx
# ifdef TINY
	repz cmpsb
# else
	repz cmpsb %es:(%di), %ss:(%si)
# endif
	jnz	.L16bit_ok
	incw	%di
	incw	%di
	movb	$2b-1b,	%cl
# ifdef TINY
	repz cmpsb
# else
	repz cmpsb %es:(%di), %ss:(%si)
# endif
	jz	.Lno_dpmi
.L16bit_ok:
	# Allocate space for the DPMI private data area.  Do this by
	# adjusting the size of our own DOS memory control block.
	pushw	%ds
	popw	%es
	movw	%si,	%bx
# ifdef TINY
	addw	$0x1000, %bx
# else
	addw	$__msdos_initial_alloc_paras, %bx
# endif
	movb	$0x4a,	%ah
	int	$0x21
	jc	.Lno_dpmi
	# Try to switch to protected mode.
	movw	%es,	%ax
# ifdef TINY
	addw	$0x1000, %ax
# else
	addw	$__msdos_initial_alloc_paras, %ax
# endif
	movw	%ax,	%es
	xorw	%ax,	%ax
# ifndef TINY
	movw	%cs,	%cx
# endif
	movw	%ss,	%dx
.Ldpmi_lcall:
	lcallw	$0,	$0
	jc	.Lno_dpmi
	# Success!  Quickly store the real mode value of %ss, which may come
	# in useful later.
# ifdef TINY
	movw	%dx,	__ia16_dpmi_rmode_ds
# else
	movw	%cx,	%ss:__ia16_dpmi_rmode_cs
	movw	%dx,	%ss:__ia16_dpmi_rmode_ds
# endif
	# Limit %cs so that it does not go beyond the end of our actual
	# code.  Note that %ax == 0 is preserved from above.
	movb	$0x08,	%al
	movw	%cs,	%bx
	xorw	%cx,	%cx
	movw	$__etext-1, %dx
	int	$0x31
	# Make %ss an expand-down descriptor, and limit it.
	movw	%ss,	%bx
	larw	%bx,	%cx
	xchgb	%cl,	%ch
	or	$0x04,	%cl
	movw	$0x0009, %ax
	int	$0x31
	jc	.Lcont_dpmi
	movw	$0x0008, %ax
	movw	%ss,	%bx
	xorw	%cx,	%cx
# ifdef TINY
	movw	$0x2c-1, %dx
	int	$0x31
	pushw	%ss
	popw	%ds
# else
	movw	$__sdata-1, %dx
	int	$0x31
# endif
.Lcont_dpmi:
.Lno_dpmi:
#endif
#ifndef TINY
	pushw	%ds
	pushw	%ss
	popw	%ds
#endif

#ifndef TINY
	# For the small memory model, we need to copy the command line
	# arguments out to the data segment, rather than modify them in
	# place in DOS's PSP --- since the PSP is outside the data segment.
	.lcomm	.Largv,	128
	# We currently do not use the PSP segment value after startup, so we
	# can overlap .Lpsp with .Largv.  This may change in the future.
	.set	.Lpsp,	.Largv
#endif

	.section .startupB, "ax"

	# Find length of environment + progname
#ifndef TINY
	popw	%ds
	movw	%ds, %ss:.Lpsp
#endif
	movw	0x2c,	%es
	xorw	%di,	%di
	cld
	xorw	%ax,	%ax
.Lfind_env_end:
	movw	$-1,	%cx
	repne	scasb
	cmpw	$-2,	%cx
	jne	.Lfind_env_end
	incw	%di
	incw	%di
	repne	scasb

	# Copy environment + progname
	pushw	%es
	popw	%ds
	pushw	%ss
	popw	%es
	incw	%di
	andw 	$-2,	%di
	subw	%di,	%sp
	movw	%di,	%cx
	movw	%sp,	%di
	xorw	%si,	%si
	rep	movsb

	# Push pointers to environment + progname
#ifdef TINY
	pushw	%es
	popw	%ds
#endif
	movw	%sp,	%di
	pushw	%ax		# envp ends with null pointer
.Lpush_env_pointers:
	pushw	%di
	movw	$-1,	%cx
	repne	scasb
	cmpw	$-2,	%cx
	jne	.Lpush_env_pointers
	popw	%cx		# don't include the final empty string
	movw	%sp,	%bp	# bp is envp
	pushw	%ax		# argv[argc] = null
	lea	2(%di),	%ax
	pushw	%ax		# argb[0] will be first after reversal
	movw	%sp,	%dx	# dx points to last item of argv

	# Parse command tail and push argument pointers
	xorw	%bx,	%bx	# argc
	movw	$0x81,	%si
#ifdef TINY
	movw	%si,	%di
#else
	movw	$.Largv, %di
	movw	%ss:(.Lpsp-.Largv)(%di), %ds
#endif
	movw	$1,	%cx

.Lspace:
	movw	%di,	%bx
	lodsb
	cmpb	$' ',	%al
	je	.Lspace
	cmpb	$'\"',	%al
	je	.Linside
	cmpb	$13,	%al
	je	.Lfinish
.Loutside_check_backslash:
	cmpb	$'\\',	%al
	je	.Loutside_backslash
.Loutside_other:
	stosb
.Loutside:
	lodsb
	cmpb	$' ',	%al
	je	.Lend_argument
	cmpb	$'\"',	%al
	je	.Loutside_quote
	cmpb	$13,	%al
	jne	.Loutside_check_backslash
.Largument_finish:
	movb	$0,	%al
	stosb
	pushw	%bx
	incw	%cx
.Lfinish:
#ifndef TINY
	pushw	%ss
	popw	%ds
#endif
	movw	%sp,	%si
	movw	%sp,	%di
	movw	%dx,	%bx
	movw	%cx,	%dx
	shrw	$1,	%cx
	jcxz	.Lno_reverse
.Ldo_reverse:
	lodsw
	xchgw	(%bx),	%ax
	stosw
	decw	%bx
	decw	%bx
	loop	.Ldo_reverse
.Lno_reverse:
	movw	%sp,	%ax
	movw	%bp,	environ
#ifndef __IA16_CALLCVT_REGPARMCALL
	pushw	%bp		# envp
	pushw	%ax		# argp
	pushw	%dx		# argc
#else
	xchgw	%ax,	%dx
	movw	%bp,	%cx
#endif
	CALL_ (main)
#if defined __IA16_CALLCVT_CDECL
	addw	$6,	%sp
#elif defined __IA16_CALLCVT_STDCALL
	# We do not know whether main (...) pops no arguments, two
	# arguments (argc, argv), or three arguments (argc, argv, envp).  So
	# pop nothing here; it should be safe to call exit (.) with extra
	# stuff on the stack.
#endif
#ifndef __IA16_CALLCVT_REGPARMCALL
	pushw	%ax
#endif
	CALL_ (exit)

.Linside_backslash_other:
#ifdef TINY
	movb	$'\\',	(%di)
#else
	movb	$'\\',	%es:(%di)
#endif
	incw	%di
.Linside_other:
	stosb
.Linside:
	lodsb
	cmpb	$'\"',	%al
	je	.Lend_argument
	cmpb	$13,	%al
	je	.Largument_finish
	cmpb	$'\\',	%al
	jne	.Linside_other
.Linside_backslash:
	lodsb
	cmpb	$'\"',	%al
	je	.Linside_backslash_quote
	cmpb	$13,	%al
	je	.Lbackslash_finish
	cmpb	$'\\',	%al
	jne	.Linside_backslash_other
.Linside_backslash_backslash:
	movb	$'\\',	%al
	stosb
	jmp	.Linside_backslash

.Loutside_backslash_backslash:
	movb	$'\\',	%al
	stosb
.Loutside_backslash:
	lodsb
	cmpb	$' ',	%al
	je	.Loutside_backslash_space
	cmpb	$'\"',	%al
	je	.Loutside_backslash_quote
	cmpb	$13,	%al
	je	.Lbackslash_finish
	cmpb	$'\\',	%al
	je	.Loutside_backslash_backslash
.Loutside_backslash_other:
#ifdef TINY
	movb	$'\\',	(%di)
#else
	movb	$'\\',	%es:(%di)
#endif
	incw	%di
	jmp	.Loutside_other

.Loutside_backslash_space:
	movb	$'\\',	%al
	stosb
.Lend_argument:
	movb	$0,	%al
	stosb
	pushw	%bx
	incw	%cx
	jmp	.Lspace

.Loutside_quote:
	mov	$0,	%al
	stosb
	pushw	%bx
	incw	%cx
	movw	%di,	%bx
	jmp	.Linside

.Lbackslash_finish:
	movb	$'\\',	%al
	stosb
	jmp	.Largument_finish

.Linside_backslash_quote:
	movb	$'\"',	%al
	jmp	.Linside_other

.Loutside_backslash_quote:
	movb	$'\"',	%al
	jmp	.Loutside_other


	.global _exit
_exit:
#ifdef __IA16_CALLCVT_REGPARMCALL
	xchgw	%ax,	%si
#endif

	.section .startupC, "ax"

#ifndef __IA16_CALLCVT_REGPARMCALL
	popw	%bx
# ifdef MEDIUM
	popw	%bx
# endif
	popw	%ax
#else
	xchgw	%ax,	%si
#endif
	movb	$0x4c,	%ah
	int	$0x21
