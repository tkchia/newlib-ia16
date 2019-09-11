#include "call-cvt.h"

	.arch i8086,jumps
	.code16
	.att_syntax prefix

	TEXT_ (memmove.S.NEWLIB)
	.global		memmove
memmove:
	ENTER_BX_(6)
	pushw	%si
	pushw	%di
	pushw	%es
	movw	%ds,	%si
	movw	%si,	%es
	MOV_ARG0W_BX_(%di)
	MOV_ARG2W_BX_(%si)
	MOV_ARG4W_BX_(%cx)
	movw	%di,	%ax
	cmpw	%di,	%si
	ja	.L1
	# dest > src => copy backwards
	addw	%cx,	%si
	addw	%cx,	%di
	decw	%di
	std
	cmpw	%si,	%di
	jne	.L2
	# dest == src + 1 => copy backwards a byte at a time
	decw	%si
	rep	movsb
	cld
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
.L2:
	# dest > src + 1 => copy backwards two bytes at a time
	decw	%di
	decw	%si
	decw	%si
	shrw	$1,	%cx
	rep	movsw
	jnc	.L3
	incw	%si
	incw	%di
	movsb
.L3:
	cld
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
.L1:
	# dest < src => copy forwards
	incw	%di
	cmpw	%si,	%di
	jne	.L4
	# dest == src - 1 => copy forwards a byte at a time
	decw	%di
	rep	movsb
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
.L4:
	# dest < src - 1 => copy forwards two bytes at a time
	decw	%di
	shrw	$1,	%cx
	rep	movsw
	adcw	%cx,	%cx
	rep	movsb
	popw	%es
	popw	%di
	popw	%si
	RET_(6)
