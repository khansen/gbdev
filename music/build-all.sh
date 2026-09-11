#!/bin/sh
target="$1"

for dir in */; do
  if [ -f "$dir/Makefile" ]; then
    echo "➡️ Entering $dir"
    if [ -n "$target" ]; then
      (cd "$dir" && make -s "$target") || echo "❌ Failed in $dir"
    else
      (cd "$dir" && make -s) || echo "❌ Failed in $dir"
    fi
  fi
done
