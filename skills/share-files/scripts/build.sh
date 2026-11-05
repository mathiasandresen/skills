#!/bin/sh
set -eu
umask 077
skill_scripts=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/share-files"
mkdir -p "$cache_dir"
output=$(mktemp "$cache_dir/.share-files.XXXXXX")
trap 'rm -f "$output"' EXIT HUP INT TERM
/usr/bin/xcrun swiftc -swift-version 5 -parse-as-library -O \
  -module-cache-path "${TMPDIR:-/tmp}/share-files-swift-cache" \
  "$skill_scripts/share-files.swift" -o "$output"
chmod 700 "$output"
mv -f "$output" "$cache_dir/share-files"
