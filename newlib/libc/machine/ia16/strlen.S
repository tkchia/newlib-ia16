#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (strlen.S.NEWLIB)
	.global		strlen
strlen:
	ENTER_BX_(2)
	pushw   %di
	pushw   %es
	MOV_ARG0W_BX_(%di)
	movw    %ds,    %ax
	movw    %ax,    %es
	movw	%di,	%bx
	xorb	%al,	%al
	movw    $-1,    %cx
	repne   scasb
	movw    %di,    %ax
	subw	%bx,	%ax
	decw    %ax
	popw    %es
	popw    %di
	RET_(2)
