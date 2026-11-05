#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/share-files-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
/usr/bin/xcrun swiftc -swift-version 5 -parse-as-library -D SHARE_FILES_TESTING \
  -module-cache-path "$test_dir/module-cache" \
  "$repo_root/share-files/scripts/share-files.swift" \
  "$repo_root/tests/share-files-tests.swift" -o "$test_dir/share-files-tests"
"$test_dir/share-files-tests"
