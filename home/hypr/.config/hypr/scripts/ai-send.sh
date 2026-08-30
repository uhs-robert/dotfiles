#!/bin/sh

set -eu

if [ "$#" -ne 3 ]; then
  printf 'usage: %s TRANSCRIPT_FILE PREFIX submit|prefill\n' "$0" >&2
  exit 2
fi

transcript_file="$1"
prefix="$2"
mode="$3"
tmux_target="AI:Claude.0"

case "$mode" in
  submit|prefill) ;;
  *)
    printf 'invalid mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac

i=0
previous_size=-1
stable_count=0

while :; do
  if [ -s "$transcript_file" ]; then
    current_size=$(wc -c < "$transcript_file")

    if [ "$current_size" -eq "$previous_size" ]; then
      stable_count=$((stable_count + 1))
      [ "$stable_count" -ge 2 ] && break
    else
      previous_size="$current_size"
      stable_count=0
    fi
  fi

  i=$((i + 1))
  [ "$i" -ge 300 ] && exit 1
  sleep 0.1
done

transcript=$(cat "$transcript_file")
[ -n "$transcript" ] || exit 0

printf '%s %s' "$prefix" "$transcript" | tmux load-buffer -
tmux paste-buffer -d -t "$tmux_target"

if [ "$mode" = "submit" ]; then
  tmux send-keys -t "$tmux_target" Enter
fi
