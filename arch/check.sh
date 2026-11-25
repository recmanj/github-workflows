#!/usr/bin/env bash
# Prints the version from `.github/scripts/upstream.sh latest` when it is newer
# than pkgver in .SRCINFO
set -euo pipefail

latest=$(.github/scripts/upstream.sh latest)
current=$(sed -n "s/^\tpkgver = //p" .SRCINFO)
if (( $(vercmp "$latest" "$current") > 0 )); then
  echo "$latest"
else
  echo "Up to date: $current" >&2
fi
