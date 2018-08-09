#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	.section	".text"
	.global		memcmp
memcmp:
	ENTER_BX_
	pushw	%si
	pushw	%di
	pushw	%es
	movw	%ds,	%si
	movw	%si,	%es
	MOV_ARG0W_BX_(%si)
	MOV_ARG2W_BX_(%di)
	MOV_ARG4W_BX_(%cx)
	movw	%cx,	%dx
	shrw	$1,	%cx
	repe	cmpsw
	jne	.L1
	testb	$1,	%dl
	jz	.L2
	cmpsb
	jne	.L3
.L2:
	xorw	%ax,	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
.L3:
	movb	-1(%si),	%al
	xorb	%ah,	%ah
	movb	-1(%di),	%dl
	xorb	%dh,	%dh
	subw	%dx,	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
.L1:
	movw	-2(%si),	%ax
	movw	-2(%di),	%dx
	cmpb	%al,	%dl
	je	.L4
	xorb	%ah,	%ah
	xorb	%dh,	%dh
	subw	%dx,	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
.L4:
	movb	%ah,	%al
	movb	%dh,	%dl
	xorb	%ah,	%ah
	xorb	%dh,	%dh
	subw	%dx,	%ax
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
