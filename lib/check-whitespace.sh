#!/bin/sh
set -eu

# `git diff --check` only inspects uncommitted changes, so it passes trivially on
# a clean checkout. Scan the tracked files this repository owns instead; the rest
# of home/ is vendored upstream and is not ours to reformat.
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(dirname -- "$script_dir")

cd "$repo_dir" || exit 1

offenders=$(
  git grep -nIE '[[:blank:]]+$' -- \
    install.sh \
    uninstall.sh \
    justfile \
    lib \
    packages \
    home/hypr/.config/hypr
) || offenders=''

if [ -n "$offenders" ]; then
  printf 'Trailing whitespace:\n%s\n' "$offenders" >&2
  exit 1
fi
