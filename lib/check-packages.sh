#!/bin/sh
set -eu

# Resolve manifests relative to the repository, not the caller's directory.
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(dirname -- "$script_dir")
pkg_dir="$repo_dir/packages"

packages=$(
  awk '
    /^[[:space:]]*($|#|\[)/ { next }
    { print $1 }
  ' \
    "$pkg_dir/arch.ini" \
    "$pkg_dir/arch-aur.ini" \
    "$pkg_dir/devtools.ini" \
    "$pkg_dir/fonts.ini" \
    "$pkg_dir/luarocks.ini" \
    "$pkg_dir/pipx.ini"
) || {
  echo "Failed to read package manifests" >&2
  exit 1
}

duplicates=$(printf '%s\n' "$packages" | sort | uniq -d)

if [ -n "$duplicates" ]; then
  printf 'Duplicate package declarations:\n%s\n' "$duplicates" >&2
  exit 1
fi
