/* Version of sbrk for DOS.  */

#include <_syslist.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>

#undef errno
extern int errno;

/* Force _heaplen to be given actual bytes in the output executable, in case
   some tools want to patch it statically (e.g. tools/ptchsize.c for FreeDOS
   command.com).  */
size_t _heaplen __attribute__ ((nocommon, section (".data"))) = 0;

void *
_sbrk (int incr)
{
  extern char __heap_end_minimum; /* Set by linker script. */
  static char *heap_end = &__heap_end_minimum;
  char *prev_heap_end;
  char *new_heap_end;

  prev_heap_end = heap_end;
  if (__builtin_add_overflow((unsigned int)heap_end, (unsigned int)incr,
			     (unsigned int*)(&new_heap_end)) ||
      (unsigned int)new_heap_end >= (unsigned int)(&prev_heap_end) - 0x80u)
    {
      errno = ENOMEM;
      return (void*)-1;
    }
  if (_heaplen != 0 && new_heap_end - &__heap_end_minimum > _heaplen)
    {
      errno = ENOMEM;
      return (void*)-1;
    }
  heap_end = new_heap_end;
  memset(prev_heap_end, 0, incr);

  return (void *) prev_heap_end;
}
