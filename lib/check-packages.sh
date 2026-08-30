#!/bin/sh
set -eu

packages=$(awk '
  /^[[:space:]]*($|#|\[)/ { next }
  { print $1 }
' \
  packages/arch.ini \
  packages/arch-aur.ini \
  packages/devtools.ini \
  packages/fonts.ini \
  packages/luarocks.ini \
  packages/pipx.ini | sort)

duplicates=$(printf '%s\n' "$packages" | uniq -d)

if [ -n "$duplicates" ]; then
  printf 'Duplicate package declarations:\n%s\n' "$duplicates" >&2
  exit 1
fi
