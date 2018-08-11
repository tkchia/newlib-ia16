/* Startup code for a "tiny" model DOS .com file with combined text and data
   segment, or a "small" model DOS .exe file with one text segment and one
   separate data segment.  */

#if !defined TINY && !defined SMALL
#error "no memory model defined -- please use either -DTINY or -DSMALL"
#endif

#ifdef __IA16_FEATURE_PUSH_IMM
	.arch i186
#else
	.arch i8086
#endif
	.code16

	.section .startupA
	.global _start
_start:
	# Sanity check for DOS version >= 2
	mov	$0x30,	%ah
	int	$0x21
	cmp	$2,	%al
	jnb	.Ldos_ok
#ifdef TINY
	ret
#else
/* Return to the `int $0x20' command at the PSP start --- we cannot just
   say `int $0x20' here, as %cs is wrong.  */
	pushw	%ds
#ifdef __IA16_FEATURE_PUSH_IMM
	pushw	$0
#else
	xorw	%ax,	%ax
	pushw	%ax
#endif
	lretw
#endif
.Ldos_ok:
#ifndef TINY
	pushw	%ss
	popw	%es
#endif
	xorw	%ax, %ax
	movw	$__sbss, %di
	movw	$__lbss, %cx
	cld
	rep	stosw
#ifndef TINY
	pushw	%ds
	pushw	%ss
	popw	%ds
#endif

#ifndef TINY
/* For the small memory model, we need to copy the command line arguments
   out to the data segment, rather than modify them in place in DOS's DTA ---
   since the DTA is outside the data segment.  */
	.lcomm	.Largv,	128
/* We currently do not use the PSP segment value after startup, so we can
   overlap .Lpsp with .Largv.  This may change in the future.  */
	.set	.Lpsp,	.Largv
#endif

	.section .startupB

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
	movw	%bp,	%bx
#endif
	call	main
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
	call	exit

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

	.section .startupC

#ifndef __IA16_CALLCVT_REGPARMCALL
	popw	%bx
	popw	%ax
#else
	xchgw	%ax,	%si
#endif
	movb	$0x4c,	%ah
	int	$0x21
