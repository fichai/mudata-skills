#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf dist
mkdir -p dist
for dir in skills/*/; do
  name="$(basename "$dir")"
  [ -f "$dir/SKILL.md" ] || { echo "falta SKILL.md en $dir" >&2; exit 1; }
  (cd skills && zip -rq "../dist/$name.zip" "$name" -x '*.DS_Store')
  echo "dist/$name.zip"
done
