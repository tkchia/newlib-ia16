/* dos-dbcs-strcspn.c internal MS-DOS DBCS aware strcspn (...) for file paths
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

#include "dbcs.h"

size_t
__msdos_dbcs_strcspn (const char *s, char reject1, char reject2,
		      _dos_dbcs_lead_table_t dbcs)
{
  const char *p = s;
  char c;

  for (;;)
    {
      c = *p;
      if (! c || c == reject1 || c == reject2)
	break;

      ++p;
      if (__msdos_dbcs_lead_byte_p (c, dbcs))
	{
	  if (! *p)
	    break;
	  ++p;
	}
    }

  return (size_t) (p - s);
}
