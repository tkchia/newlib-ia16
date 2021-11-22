/* dos-realpath.c canonicalize a pathname
 *
 * Copyright (c) 2021 TK Chia
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

#include <errno.h>
#include <inttypes.h>
#include <limits.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "dbcs.h"
#include "pmode.h"

#ifndef FP_SEG
#define FP_SEG(x) \
  __builtin_ia16_selector ((unsigned)((unsigned long)(void __far *)(x) >> 16))
#endif
#ifndef FP_OFF
#define FP_OFF(x) ((unsigned) (unsigned long) (void __far *) (x))
#endif

struct __attribute__ ((packed)) fcb
{
  uint8_t drive, name[8], ext[3], unused[25];
};

extern unsigned char __msdos_getdrive (void);
extern char *__msdos_getcwd (char[PATH_MAX], unsigned char);

static bool
__msdos_truename (const char *path, char *out_path)
{
  /*
   * Make doubly sure that the input & output buffers do not overlap for the
   * "truename" syscall...
   */
  char buf[PATH_MAX];
  int err, carry;

  __asm volatile (RMODE_DOS_CALL_ "; sbbw %1, %1"
		  : "=a" (err), "=r" (carry)
		  : "Rah" ((uint8_t) 0x60),
		    "Rds" (FP_SEG (path)), "S" (FP_OFF (path)),
		    "e" (FP_SEG (buf)), "D" (FP_OFF (buf))
		  : "cc", "memory");

  if (carry)
    {
      errno = err;
      return false;
    }

  strcpy (out_path, buf);
  return true;
}

static const char *__msdos_parse_to_fcb (const char *name, struct fcb *fcb)
{
  uint16_t ax;
  const char *end;

  memset (fcb, 0, sizeof (struct fcb));

  __asm volatile (RMODE_DOS_CALL_
		  : "=a" (ax), "=S" (end)
		  : "0" (0x2900u),
		    "Rds" (FP_SEG (name)), "1" (FP_OFF (name)),
		    "e" (FP_SEG (fcb)), "D" (FP_OFF (fcb))
		  : "cc", "memory");

  if ((uint8_t) ax > 1)
    return NULL;

  return end;
}

static bool
__msdos_path_sep_p (char c)
{
  switch (c)
    {
    case '\\':
    case '/':
      return true;
    default:
      return false;
    }
}

#define COPY(chrs, len) \
	do \
	  { \
	    if (j > PATH_MAX - (len)) \
	      { \
		errno = ENAMETOOLONG; \
		goto bail; \
	      } \
	    memcpy (out_path + j, (chrs), (len)); \
	    j += (len); \
	  } \
	while (0)
#define COPY1(chr) \
	do \
	  { \
	    if (j >= PATH_MAX) \
	      { \
		errno = ENAMETOOLONG; \
		goto bail; \
	      } \
	    out_path[j++] = (chr); \
	  } \
	while (0)

char *
realpath (const char *path, char *out_path)
{
  size_t i = 0, j = 0;
  bool out_path_alloced = false;
  unsigned char drive;
  char c;
  /*
   * To keep track of the number of path components in the output, & where
   * each component begins (& ends).
   */
  size_t n_comps, comp_start[PATH_MAX / 2];
  _dos_dbcs_lead_table_t dbcs = (_dos_dbcs_lead_table_t) 0L;

  if (! path || ! path[0])
    goto invalid;

  if (! out_path)
    {
      out_path = malloc (PATH_MAX);
      if (! out_path)
	return NULL;
      out_path_alloced = true;
    }

  /*
   * If the path is a network path, then just do a "truename" syscall & call
   * it a day.
   */
  if (path[1] == '\\' && path[0] == '\\')
    {
      if (__msdos_truename (path, out_path))
	return out_path;
      goto bail;
    }

  dbcs = _dos_get_dbcs_lead_table ();

  /* Not a network path.  Process any drive letter. */
  if (path[1] == ':' && ! __msdos_dbcs_lead_byte_p (path[0], dbcs))
    {
      drive = path[0];
      switch (drive)
	{
	case 'A' ... 'Z':
	  drive -= 'A' - 1;
	  break;
	case 'a' ... 'z':
	  drive -= 'a' - 1;
	  break;
	default:
	  goto invalid;
	}

      i = 2;
    }
  else
    drive = __msdos_getdrive () + 1;

  /*
   * Is the first character (after any drive letter) a path separator?   If
   * not, then try to find the working directory of the given drive.  If that
   * fails, arrange to return a relative path.
   */
  if (drive)
    {
      if (__msdos_path_sep_p (path[i]))
	{
	  out_path[j++] = drive - 1 + 'A';
	  out_path[j++] = ':';
	  out_path[j++] = '\\';
	  ++i;
	  n_comps = 1;
	  comp_start[0] = j;
	}
      else if (__msdos_getcwd (out_path, drive))
	{
	  char *p = out_path;
	  n_comps = 0;
	  while ((c = *p++) != 0)
	    {
	      if (__msdos_dbcs_lead_byte_p (c, dbcs))
		{
		  if (! *p++)
		    break;
		}
	      else if (__msdos_path_sep_p (c))
		{
		  comp_start[n_comps] = p - out_path;
		  ++n_comps;
		}
	    }
	  /*
	   * p now points after the null terminator from the obtained
	   * current directory.  We add a trailing backslash if the last
	   * (possibly multi-byte) character seen was not a path separator.
	   */
	  j = p - 1 - out_path;
	  if (! n_comps || comp_start[n_comps - 1] != j)
	    {
	      out_path[j++] = '\\';
	      comp_start[n_comps] = j;
	      ++n_comps;
	    }
	}
      else
	{
	  out_path[j++] = drive - 1 + 'A';
	  out_path[j++] = ':';
	  n_comps = 1;
	  comp_start[0] = j;
	}
    }

  /* Process the rest of the path, component by component. */
  while (path[i] != 0)
    {
      struct fcb fcb;
      size_t name_len, ext_len;

      size_t k = __msdos_dbcs_strcspn (path + i, '\\', '/', dbcs), m;
      switch (k)
	{
	case 0:
	  ++i;
	  continue;

	case 1:
	  if (path[i] == '.')
	    {
	      ++i;
	      continue;
	    }
	  break;

	case 2:
	  if (path[i] == '.' && path[i + 1] == '.')
	    {
	      i += 2;
	      if (n_comps > 1)
		{
		  j = comp_start[n_comps - 2];
		  --n_comps;
		}
	      else
		{
		  j = comp_start[0];
		  COPY ("..\\", 3);
		  comp_start[0] = j;
		}
	      continue;
	    }
	  break;

	default:
	  ;
	}

      if (__msdos_parse_to_fcb (path + i, &fcb) != path + i + k
	  || fcb.drive != 0)
	goto invalid;

      i += k;

      name_len = m = 0;
      do
	{
	  c = (char) fcb.name[m];
	  ++m;
	  if (c != ' ')
	    {
	      if (m < 8 && __msdos_dbcs_lead_byte_p (c, dbcs))
		++m;
	      name_len = m;
	    }
	}
      while (m < 8);

      ext_len = m = 0;
      do
	{
	  c = (char) fcb.ext[m];
	  ++m;
	  if (c != ' ')
	    {
	      if (m < 3 && __msdos_dbcs_lead_byte_p (c, dbcs))
		++m;
	      ext_len = m;
	    }
	}
      while (m < 3);

      if (! name_len)
	goto invalid;

      COPY (fcb.name, name_len);
      if (ext_len)
	{
	  COPY1 ('.');
	  COPY (fcb.ext, ext_len);
	}
      COPY1 ('\\');
      comp_start[n_comps] = j;
      ++n_comps;
    }

  /* We are done. */
  if (j > 3)
    out_path[j - 1] = 0;
  else
    out_path[j] = 0;

  return out_path;

invalid:
  errno = EINVAL;
bail:
  if (out_path_alloced)
    free (out_path);
  _dos_free_dbcs_lead_table (dbcs);
  return NULL;
}
