/*
 * Macros to handle different function calling conventions.
 *
 * Copyright (c) 2018--2019 TK Chia
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

/*
 * These macros partially abstract away the differences between the
 * `stdcall', `cdecl', and `regparmcall' calling conventions, and the `tiny'/
 * `small' and `medium' memory models, as implemented in ia16-elf-gcc.
 *
 * - SEG_RELOC_ (PLACE, SYM) installs an IA-16 segment relocation for the
 *   symbol SYM at PLACE.
 *
 * - TEXT_ (TAG) or DATA_ (TAG) switches to a text or data section.  Whether
 *   the section is near or far will depend on the memory model.  The section
 *   name may include a tag TAG to indicate the module it belongs to.
 *
 * - JMP_ (FUNC) or CALL_ (FUNC) does a jump or a call to the function FUNC.
 *   Whether the jump or call is near or far will depend on the memory model.
 *
 * - TEXT_PTR_ (FUNC) emits a near or far pointer --- depending on the memory
 *   model --- to the function FUNC.
 *
 * - ENTER_BX_ (N) loads %sp into %bx to access stack arguments, if necessary.
 *   N is the number of bytes of arguments passed to the function.
 *
 *   ENTER_BX_ (.) should occur before any other pushes to save registers
 *   (e.g. `pushw %si').
 *
 * - ENTER2_BX_ (N) does the same as ENTER_BX_ (N), except that for the
 *   `regparmcall' convention, it assumes that the function uses only two
 *   registers (%ax and %dx) to hold parameters.
 *
 * - ARG0W_BX_, ARG2W_BX_, ARG4W_BX_, ARG6W_BX_, or ARG8W_BX_ refers
 *   respectively to the first, second, third, fourth, or fifth argument
 *   shortword.  Each of these macros should be used only after ENTER_BX_.
 *
 * - MOV_ARG0W_BX_ (REG), MOV_ARG2W_BX_ (REG), MOV_ARG4W_BX_ (REG),
 *   MOV_ARG6W_BX_ (REG), or MOV_ARG8W_BX_ (REG) moves the first, second,
 *   third, fourth, or fifth argument shortword into REG, respectively, if
 *   necessary.  Each of these macros should be used only after ENTER_BX_.
 *
 * - MOV_ARG0W_BX_CLOBBER_ (REG), MOV_ARG2W_BX_CLOBBER_ (REG), or
 *   MOV_ARG4W_BX_CLOBBER_ (REG) moves the first, second, or third argument
 *   shortword into REG.  If the `regparmcall' convention is in effect, and
 *   REG or the original argument location happens to be %ax, the macro may
 *   choose to use the 1-byte `xchgw %ax, ...' instruction (shorter than
 *   the 2-byte `movw ..., %ax' or `movw %ax, ...'), and clobber the original
 *   argument.  This is useful when we are optimizing for size (-Os).
 *
 * - MOV_ARG4W2_BX_ (REG), MOV_ARG6W2_BX_ (REG), and MOV_ARG8W2_BX_ (REG) do
 *   the same as MOV_ARG4W_BX_ (REG), MOV_ARG6W_BX_ (REG), and MOV_ARG8W_BX_
 *   (REG) respectively, except that for the `regparmcall' convention, they
 *   assume that the function uses only two registers (%ax and %dx) to hold
 *   parameters.
 *
 * - MOV_ARG0B_BX_ (REG), MOV_ARG2B_BX_ (REG), MOV_ARG4B_BX_ (REG), or
 *   MOV_ARG6B_BX_ (REG), or MOV_ARG8B_BX_ (REG) moves the low byte of the
 *   first, second, third, fourth, or fifth argument shortword into REG,
 *   respectively, if necessary.  Each of these macros should be used only
 *   after ENTER_BX_.
 *
 * - MOV_ARG8B2_BX_ (REG) does the same as MOV_ARG8B_BX_(REG), except that
 *   for the `regparmcall' convention, they assume that the function uses
 *   only two registers (%ax and %dx) to hold parameters.
 *
 * - LDS_ARG0W_BX_ (REG) moves the first shortword into REG, and the second
 *   into %ds; LES_ARG0W_BX_ (REG) moves the shortwords into REG and %es.
 *   Each of these macros should be used only after ENTER_BX_.
 *
 * - LDS_ARG2W_BX_ (REG) moves the second shortword into REG, and the third
 *   into %ds; LES_ARG2W_BX_ (REG) moves the shortwords into REG and %es.
 *   Each of these macros should be used only after ENTER_BX_.
 *
 * - LDS_ARG4W2_BX_ (REG) moves the third shortword into REG, and the fourth
 *   into %ds; LES_ARG4W2_BX_ (REG) moves the shortwords into REG and %es. 
 *   For the `regparmcall' convention, these macros assume that the function
 *   uses only two registers (%ax and %dx) to hold parameters.  Each of
 *   these macros should be used only after ENTER_BX_.
 *
 * - RET_(N) emits an instruction to return from a function with N bytes of
 *   arguments.
 *
 * - RET2_(N) does the same as RET_(N), except that for the `regparmcall'
 *   convention, it assumes that the function uses only two registers (%ax and
 *   %dx) to hold parameters.
 *
 * When using the MOV_*, LDS_*, or LES_* macros, be careful not to clobber a
 * `regparmcall' argument register before it is read, and be careful not to
 * clobber %bx itself for the `cdecl' and `stdcall' conventions.
 */

#ifdef __IA16_ABI_SEGELF
# define AUX__(func)		AUX___(func##!)
# define SEG_RELOC_(place, sym) .reloc (place), R_386_SEG16, AUX__(sym)
#else
# define SEG_RELOC_(place, sym) .reloc (place), R_386_OZSEG16, sym
#endif
#ifndef __IA16_CMODEL_IS_FAR_TEXT
# define FAR_ADJ__		0
# define RET__			ret
# define JMP_(func)		jmp func
# define CALL_(func)		call func
# define TEXT_(tag)		.text
# define TEXT_PTR_(func)	.hword func
#else
# define FAR_ADJ__		2
# define RET__			lret
# define AUX___(aux)		#aux
# define JMP_(func)		SEG_RELOC_ (.+3, func); \
				ljmp $0, $func
# define CALL_(func)		SEG_RELOC_ (.+3, func); \
				lcall $0, $func
# define TEXT_(tag)		.section AUX___(.fartext.f.##tag##$), "ax"
# define TEXT_PTR_(func)	SEG_RELOC_ (.+2, func); \
				.hword func, 0
#endif
#define DATA_(tag)		.data
#if defined __IA16_CALLCVT_REGPARMCALL
# if __IA16_REGPARMCALL_ABI - 0 != 20180814L
#   warning "regparmcall convention is not 20180814L, output code may be bogus"
# endif
# define ENTER_BX_(n)		.if (n)>6; \
				movw %sp, %bx; \
				.endif
# define ENTER2_BX_(n)		.if (n)>4; \
				movw %sp, %bx; \
				.endif
# define ARG0W_BX_		%ax
# define ARG2W_BX_		%dx
# define ARG4W_BX_		%cx
# define ARG6W_BX_		FAR_ADJ__+2(%bx)
# define ARG8W_BX_		FAR_ADJ__+4(%bx)
# define MOV_ARG0W_BX_(reg)	.ifnc %ax, reg; \
				movw %ax, reg; \
				.endif
# define MOV_ARG2W_BX_(reg)	.ifnc %dx, reg; \
				movw %dx, reg; \
				.endif
# define MOV_ARG4W_BX_(reg)	.ifnc %cx, reg; \
				movw %cx, reg; \
				.endif
# define MOV_ARG4W2_BX_(reg)	movw FAR_ADJ__+2(%bx), reg
# define MOV_ARG6W_BX_(reg)	movw FAR_ADJ__+2(%bx), reg
# define MOV_ARG6W2_BX_(reg)	movw FAR_ADJ__+4(%bx), reg
# define MOV_ARG8W_BX_(reg)	movw FAR_ADJ__+4(%bx), reg
# define MOV_ARG8W2_BX_(reg)	movw FAR_ADJ__+6(%bx), reg
# ifdef __OPTIMIZE_SIZE__
#   define MOV_ARG0W_BX_CLOBBER_(reg) \
				.ifnc %ax, reg; \
				xchgw %ax, reg; \
				.endif
#   define MOV_ARG2W_BX_CLOBBER_(reg) \
				.ifnc %dx, reg; \
				.ifc %ax, reg; \
				xchgw %ax, %dx; \
				.else; \
				movw %dx, reg; \
				.endif; \
				.endif
#   define MOV_ARG4W_BX_CLOBBER_(reg) \
				.ifnc %cx, reg; \
				.ifc %ax, reg; \
				xchgw %ax, %cx; \
				.else; \
				movw %cx, reg; \
				.endif; \
				.endif
# else
#   define MOV_ARG0W_BX_CLOBBER_(reg) MOV_ARG0W_BX_(reg)
#   define MOV_ARG2W_BX_CLOBBER_(reg) MOV_ARG2W_BX_(reg)
#   define MOV_ARG4W_BX_CLOBBER_(reg) MOV_ARG4W_BX_(reg)
# endif
# define MOV_ARG0B_BX_(reg)	.ifnc %al, reg; \
				movb %al, reg; \
				.endif
# define MOV_ARG2B_BX_(reg)	.ifnc %dl, reg; \
				movb %dl, reg; \
				.endif
# define MOV_ARG4B_BX_(reg)	.ifnc %cl, reg; \
				movb %cl, reg; \
				.endif
# define MOV_ARG6B_BX_(reg)	movb FAR_ADJ__+2(%bx), reg
# define MOV_ARG8B_BX_(reg)	movb FAR_ADJ__+4(%bx), reg
# define MOV_ARG8B2_BX_(reg)	movb FAR_ADJ__+6(%bx), reg
# define LDS_ARG0W_BX_(reg)	movw %dx, %ds; \
				.ifnc %ax, reg; \
				movw %ax, reg; \
				.endif
# define LES_ARG0W_BX_(reg)	movw %dx, %es; \
				.ifnc %ax, reg; \
				movw %ax, reg; \
				.endif
# define LDS_ARG2W_BX_(reg)	movw %cx, %ds; \
				.ifnc %dx, reg; \
				movw %dx, reg; \
				.endif
# define LES_ARG2W_BX_(reg)	movw %cx, %es; \
				.ifnc %dx, reg; \
				movw %dx, reg; \
				.endif
# define LDS_ARG4W2_BX_(reg)	ldsw FAR_ADJ__+2(%bx), reg
# define LES_ARG4W2_BX_(reg)	lesw FAR_ADJ__+2(%bx), reg
# define RET_(n)		.if (n)>6; \
				RET__ $((n)-6); \
				.else; \
				RET__; \
				.endif
# define RET2_(n)		.if (n)>4; \
				RET__ $((n)-4); \
				.else; \
				RET__; \
				.endif
#else
# define ENTER_BX_(n)		movw %sp, %bx
# define ENTER2_BX_(n)		movw %sp, %bx
# define ARG0W_BX_		FAR_ADJ__+2(%bx)
# define ARG2W_BX_		FAR_ADJ__+4(%bx)
# define ARG4W_BX_		FAR_ADJ__+6(%bx)
# define ARG6W_BX_		FAR_ADJ__+8(%bx)
# define ARG8W_BX_		FAR_ADJ__+10(%bx)
# define MOV_ARG0W_BX_(reg)	movw FAR_ADJ__+2(%bx), reg
# define MOV_ARG2W_BX_(reg)	movw FAR_ADJ__+4(%bx), reg
# define MOV_ARG4W_BX_(reg)	movw FAR_ADJ__+6(%bx), reg
# define MOV_ARG4W2_BX_(reg)	movw FAR_ADJ__+6(%bx), reg
# define MOV_ARG6W_BX_(reg)	movw FAR_ADJ__+8(%bx), reg
# define MOV_ARG6W2_BX_(reg)	movw FAR_ADJ__+8(%bx), reg
# define MOV_ARG8W_BX_(reg)	movw FAR_ADJ__+10(%bx), reg
# define MOV_ARG8W2_BX_(reg)	movw FAR_ADJ__+10(%bx), reg
# define MOV_ARG0W_BX_CLOBBER_(reg) MOV_ARG0W_BX_(reg)
# define MOV_ARG2W_BX_CLOBBER_(reg) MOV_ARG2W_BX_(reg)
# define MOV_ARG4W_BX_CLOBBER_(reg) MOV_ARG4W_BX_(reg)
# define MOV_ARG0B_BX_(reg)	movb FAR_ADJ__+2(%bx), reg
# define MOV_ARG2B_BX_(reg)	movb FAR_ADJ__+4(%bx), reg
# define MOV_ARG4B_BX_(reg)	movb FAR_ADJ__+6(%bx), reg
# define MOV_ARG6B_BX_(reg)	movb FAR_ADJ__+8(%bx), reg
# define MOV_ARG8B_BX_(reg)	movb FAR_ADJ__+10(%bx), reg
# define MOV_ARG8B2_BX_(reg)	movb FAR_ADJ__+10(%bx), reg
# define LDS_ARG0W_BX_(reg)	ldsw FAR_ADJ__+2(%bx), reg
# define LES_ARG0W_BX_(reg)	lesw FAR_ADJ__+2(%bx), reg
# define LDS_ARG2W_BX_(reg)	ldsw FAR_ADJ__+4(%bx), reg
# define LES_ARG2W_BX_(reg)	lesw FAR_ADJ__+4(%bx), reg
# define LDS_ARG4W2_BX_(reg)	ldsw FAR_ADJ__+6(%bx), reg
# define LES_ARG4W2_BX_(reg)	lesw FAR_ADJ__+6(%bx), reg
# ifdef __IA16_CALLCVT_STDCALL
#   define RET_(n)		.if (n); \
				RET__ $(n); \
				.else; \
				RET__; \
				.endif
# else
#   ifndef __IA16_CALLCVT_CDECL
#     warning "not sure which calling convention is in use; assuming cdecl"
#   endif
#   define RET_(n)		RET__
# endif
# define RET2_(n)		RET_ (n)
#endif
