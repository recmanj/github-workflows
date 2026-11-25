#!/usr/bin/env bash
# Lints, builds, installs and smoke tests the PKGBUILD in the current
# directory, as root. Only run this in jobs with a read-only token and nothing
# that later publishes from the workspace.
#
# Optional hooks in the package repo:
#   keys/pgp/*.asc               keys for validpgpkeys
#   .github/scripts/upstream.sh  `sums VERSION` must match the PKGBUILD
#   .github/scripts/smoke-test.sh  run as root after installing the package
set -euo pipefail
shopt -s nullglob

scripts=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

pacman -Syu --noconfirm --needed namcap shellcheck

# Dependencies that are not in the repos, such as other AUR packages, are left
# out. The build then skips dependency checks and the install ignores them.
available=()
missing=()
while read -r dep; do
  if pacman -Sp "$dep" &> /dev/null; then
    available+=("$dep")
  else
    missing+=("$dep")
  fi
done < <(sed -nE "s/^\t(make|check)?depends(_$(uname -m))? = //p" .SRCINFO)
if (( ${#available[@]} )); then
  pacman -S --noconfirm --needed --asdeps "${available[@]}"
fi
if (( ${#missing[@]} )); then
  echo "::warning::Not in the repos, not installed: ${missing[*]}"
fi

id builder &> /dev/null || useradd -m builder
chown -R builder: .

sudo -u builder SCRIPTS="$scripts" NODEPS="${missing:+--nodeps}" bash -euo pipefail <<'BUILD'
shopt -s nullglob

keys=(keys/pgp/*.asc)
if (( ${#keys[@]} )); then
  gpg --batch --import "${keys[@]}"
fi

echo '::group::.SRCINFO is up to date'
diff -u .SRCINFO <(makepkg --printsrcinfo)
echo '::endgroup::'

echo '::group::shellcheck'
shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164 PKGBUILD
for f in *.install .github/scripts/*.sh; do
  shellcheck --shell=bash "$f"
done
echo '::endgroup::'

if [[ -x .github/scripts/upstream.sh ]]; then
  echo '::group::Checksums match upstream'
  diff -u <(.github/scripts/upstream.sh sums "$(source PKGBUILD; echo "$pkgver")") \
    <("$SCRIPTS/pkgbuild-sums.sh")
  echo '::endgroup::'
fi

# --verifysource only checks CARCH
for arch in $(source PKGBUILD; echo "${arch[@]}"); do
  echo "::group::Checksums and signatures ($arch)"
  sed "s/^CARCH=.*/CARCH=\"$arch\"/" /etc/makepkg.conf > "/tmp/makepkg-$arch.conf"
  makepkg --config "/tmp/makepkg-$arch.conf" --verifysource --noconfirm
  echo '::endgroup::'
done

echo '::group::namcap PKGBUILD'
namcap PKGBUILD | tee /tmp/namcap.txt
echo '::endgroup::'

echo '::group::Build'
# shellcheck disable=SC2086
PKGEXT=.pkg.tar makepkg --cleanbuild --noconfirm $NODEPS
echo '::endgroup::'

echo '::group::namcap package'
namcap ./*.pkg.tar | tee -a /tmp/namcap.txt
echo '::endgroup::'

if grep -q ' E: ' /tmp/namcap.txt; then
  echo '::error::namcap reported errors'
  exit 1
fi
BUILD

echo '::group::Install'
# -dd skips the dependencies left out above
pacman -U --noconfirm ${missing:+-dd} ./*.pkg.tar
echo '::endgroup::'

if [[ -e .github/scripts/smoke-test.sh ]]; then
  echo '::group::Smoke test'
  .github/scripts/smoke-test.sh
  echo '::endgroup::'
fi
