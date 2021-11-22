/* dos-statr.c basic _stat_r for DOS
 *
 * Copyright (c) 2018 Bart Oldeman
 * Copyright (c) 2019--2021 TK Chia
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

#include <string.h>
#include <ctype.h>
#include <time.h>
#include <sys/stat.h>
#include <errno.h>
#include <_syslist.h>
#include <reent.h>
#include "dbcs.h"
#include "pmode.h"

#ifndef FP_SEG
#define FP_SEG(x) \
  __builtin_ia16_selector ((unsigned)((unsigned long)(void __far *)(x) >> 16))
#endif

extern time_t __msdos_cvt_file_time (unsigned, unsigned);

#define _A_RDONLY 1
#define _A_HIDDEN 2
#define _A_SYSTEM 4
#define _A_SUBDIR 0x10
#define _A_ARCHIVE 0x20
#define ALL_FILES (_A_RDONLY|_A_HIDDEN|_A_SYSTEM|_A_SUBDIR|_A_ARCHIVE)

struct _find_t {
  char reserved[21];
  unsigned char attrib;
  unsigned short time __attribute__((packed));
  unsigned short date __attribute__((packed));
  unsigned long size __attribute__((packed));
  char name[13];
};

static void dos_set_dta (void __far *dta)
{
  asm volatile (RMODE_DOS_CALL_ : :
	        "Rah"((char)0x1a),
		"d"((unsigned)(unsigned long)(dta)), "Rds"(FP_SEG(dta)));
}

static unsigned char dos_getdrive (void)
{
  unsigned char ret;
  asm volatile ("int $0x21" : "=a"(ret) : "Rah"((char)0x19));
  return ret;
}

static int dos_findfirst (struct _reent *reent, const char *path,
			  struct _find_t *findbuf)
{
  int ret, carry;
  dos_set_dta (findbuf);
  asm volatile ("int $0x21; sbb %0, %0" :
		"=r"(carry), "=a"(ret) :
	        "Rah"((char)0x4e), "c"(ALL_FILES),
		"d"(path), "Rds"(FP_SEG(path)) : "cc", "memory");
  if (carry)
    {
      reent->_errno = ret;
      return carry;
    }
  return ret;
}

int
_stat_r (struct _reent *reent, const char * restrict path,
	 struct stat * restrict buf)
{
  struct _find_t findbuf;
  unsigned char attr;
  _dos_dbcs_lead_table_t dbcs = _dos_get_dbcs_lead_table ();

  /* Check that the PATH is not itself a wildcard.  (This does not handle
     Windows-style \\?\... UNC paths, but from what I know, DOS does not have
     these anyway.)  */
  size_t wild_pos = __msdos_dbcs_strcspn (path, '*', '?', dbcs);

  if (path[wild_pos] != 0)
    {
      reent->_errno = ENOENT;
      _dos_free_dbcs_lead_table (dbcs);
      return -1;
    }

  if (dos_findfirst (reent, path, &findbuf))
    {
      _dos_free_dbcs_lead_table (dbcs);
      return -1;
    }

  /* zero any fields that don't really apply to DOS,
     or findfirst does not provide */
  memset (buf, 0, sizeof *buf);
  attr = findbuf.attrib;
  buf->st_mode = ((attr & _A_RDONLY) ? 0 : (S_IWUSR | S_IWGRP | S_IWOTH)) |
    (S_IRUSR | S_IXUSR | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH) |
    ((attr & _A_SUBDIR) ? (S_IFDIR|S_IEXEC) : S_IFREG);
  buf->st_mtime = buf->st_atime = buf->st_ctime
    = __msdos_cvt_file_time (findbuf.date, findbuf.time);
  buf->st_size = findbuf.size;
  if (path[1] == ':' && ! __msdos_dbcs_lead_byte_p (path[0], dbcs))
    buf->st_dev = toupper (path[0]) - 'A';
  else
    buf->st_dev = dos_getdrive ();
  buf->st_nlink = 1;

  _dos_free_dbcs_lead_table (dbcs);
  return 0;
}
