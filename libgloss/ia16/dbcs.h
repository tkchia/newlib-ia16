/*
 * Declarations for working with MS-DOS double-byte character set (DBCS)
 * lead byte tables.
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

#include <stdbool.h>
#include <stdlib.h>

typedef unsigned short __attribute__ ((packed)) __far *_dos_dbcs_lead_table_t;

/*
 * The routine name _dos_get_dbcs_lead_table () comes from Open Watcom's
 * library internal interfaces.
 */
extern _dos_dbcs_lead_table_t _dos_get_dbcs_lead_table (void);
#ifdef __IA16_FEATURE_PROTECTED_MODE
extern void _dos_free_dbcs_lead_table (_dos_dbcs_lead_table_t);
#else
static inline void _dos_free_dbcs_lead_table (_dos_dbcs_lead_table_t dbcs)
{
}
#endif
extern bool __msdos_dbcs_lead_byte_p (char, _dos_dbcs_lead_table_t);
extern size_t __msdos_dbcs_strcspn (const char *, char, char,
				    _dos_dbcs_lead_table_t);
