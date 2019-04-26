#!/bin/sh
# Copyright (c) 2019 TK Chia
#
# The authors hereby grant permission to use, copy, modify, distribute,
# and license this software and its documentation for any purpose, provided
# that existing copyright notices are retained in all copies and that this
# notice is included verbatim in any distributions. No written agreement,
# license, or royalty fee is required for any of the authorized uses.
# Modifications to this software may be copyrighted by their authors
# and need not follow the licensing terms described here, provided that
# the new terms are clearly indicated on the first page of each file where
# they apply.

# When building Newlib multilibs for IA-16, this wrapper script can be used
# in place of the actual ia16-elf-gcc, so that Newlib's `configure' script
# will exclude the elks-libc multilib directories from the multilib build ---
# we do not need to build Newlib at all for these.
#
# The alternative to having such a wrapper script is to hack config-ml.in,
# but that is somewhat intrusive, and messy (I _do_ want to build libgcc
# for the elks-libc multilibs, for instance).  -- tkchia

set -e
filter=false
for arg in ${1+"$@"}; do
  case "$arg" in
  -print-multi-lib | --print-multi-lib)
    filter=true;;
  esac
done
if "$filter"; then
  ia16-elf-gcc ${1+"$@"} | grep -v '@melks-libc'
else
  exec ia16-elf-gcc ${1+"$@"}
fi
