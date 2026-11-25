# arch-ci.yml

Validates the PKGBUILD at the root of the repo in an `archlinux:base-devel`
container:

1. `.SRCINFO` matches `makepkg --printsrcinfo`.
2. shellcheck passes on the PKGBUILD, `*.install` and `.github/scripts/*.sh`.
3. If `.github/scripts/upstream.sh` exists, its `sums` output matches the
   PKGBUILD. See [`arch-update.yml`](arch-update.md).
4. The sources download and match their checksums and signatures, for every
   arch in `arch`.
5. namcap reports no errors for the PKGBUILD or the package.
6. The package builds and installs.
7. If `.github/scripts/smoke-test.sh` exists, it runs as root.

Keys for `validpgpkeys` are imported from `keys/pgp/*.asc`.

Dependencies that are not in the Arch repos, such as other AUR packages, are
skipped with a warning. The build then runs with `--nodeps` and the package is
installed with `-dd`.

```yaml
on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  validate:
    uses: recmanj/github-workflows/.github/workflows/arch-ci.yml@<sha> # v1.0.0
    permissions:
      contents: read
```

The image is pinned by digest in `arch-ci.yml` and `arch-update.yml`. Dependabot
does not update images in workflows, so it has to be bumped by hand.
