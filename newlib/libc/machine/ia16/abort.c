/*
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
 * This file now only contains an internal __ia16_abort_impl (.) routine
 * used by the user-callable abort ().
 *
 * abort () for MS-DOS now has implementations for the tiny, small, and
 * medium memory models, under the libgloss/ia16/ subtree.
 *
 * There is currently no abort () implementation for ELKS.
 *
 * TODO: move this file into libgloss/ia16/ too?  -- tkchia 20190913
 */

#include <signal.h>
#include <unistd.h>

#ifdef __MSDOS__
# define NL		"\r\n"
#else
# define NL		"\n"
#endif
#define MK_FP(seg, off)	((void __far *) \
			 ((unsigned long) (unsigned) (seg) << 16 \
			  | (unsigned) (off)))

typedef struct {
  unsigned ax, bx, cx, dx, bp, si, di, cs, es, ds, ss, sp, flags;
} abort_regs_t;

static void
dump_mem (const unsigned __far *mem, unsigned n_words)
{
  unsigned word;
  char buf[5];

  buf[4] = ' ';
  while (n_words-- != 0)
    {
      word = *mem++;
      buf[3] = "0123456789abcdef"[word & 0xf];
      word >>= 4;
      buf[2] = "0123456789abcdef"[word & 0xf];
      word >>= 4;
      buf[1] = "0123456789abcdef"[word & 0xf];
      word >>= 4;
      buf[0] = "0123456789abcdef"[word];
      write (2, buf, 5);
    }
}

void
__ia16_abort_impl (abort_regs_t regs)
{
  static const char msg1[] = NL "abort () called" NL
				"reg (a-d bp si di cs es ds ss sp f):" NL,
		    msg2[] = NL "stk:" NL;

  write (2, msg1, sizeof (msg1) - 1);
  dump_mem ((const unsigned *) &regs, sizeof (regs) / sizeof (unsigned));
  write (2, msg2, sizeof (msg2) - 1);
  dump_mem ((const unsigned *) MK_FP (regs.ss, regs.sp), 192);

#ifndef __IA16_FEATURE_PROTECTED_MODE
  /* _exit (.) may ultimately make the system weird out and wipe the
     information dump from the screen.  Try to delay a bit before actually
     exiting, if possible.

     If we are not compiling for protected mode, then it should be fine to
     use the `hlt' instruction.  */
  {
    unsigned delay = 64;
    while (delay-- != 0)
      __asm volatile ("hlt");
  }
#endif

  for (;;)
    _exit (128 | SIGABRT);
}
