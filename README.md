# github-workflows

Reusable GitHub Actions workflows. Pin them to a commit:

```yaml
uses: recmanj/github-workflows/.github/workflows/update.yml@<sha> # v1.0.0
```

## update.yml

Opens a pull request when upstream has a new version. The caller passes shell
commands:

- `check` prints the version to update to, or nothing when up to date.
- `pin` prints data about `$VERSION` that must not change before the pull
  request is opened, such as checksums. Optional.
- `apply` updates the files to `$VERSION`, given `$PIN`.
- `validate` tests the result. Optional.

The `check` job runs `check` and, unless a pull request for `update/<version>`
already exists, `pin`. The `validate` job runs `apply` and `validate` with a
read-only token. It is the only job that should run anything from the new
version. The `publish` job runs `apply` on a fresh checkout and opens the pull
request with the changed tracked files. `apply` runs there before the token is
used, but must not run anything from the new version either, since that could
change what gets committed.

The caller needs to grant `contents: write`, `pull-requests: write` and
`actions: write`. The last one is for `ci-workflow`, which runs CI on the new
branch, as pull requests opened with `GITHUB_TOKEN` do not trigger workflows.

```yaml
on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:

jobs:
  update:
    uses: recmanj/github-workflows/.github/workflows/update.yml@<sha>
    permissions:
      contents: write
      pull-requests: write
      actions: write
    with:
      check: ./scripts/check-update.sh
      apply: ./scripts/bump.sh "$VERSION"
      validate: make test
      ci-workflow: ci.yml
```

The commands run with bash in the caller's checkout. `$WORKFLOWS_DIR` points at
this repository at the commit being run, for the helpers below. The other inputs
are described in the workflow. If you pass `container`, pin it by digest.

## Arch packages

`arch-ci.yml` lints, builds and installs the PKGBUILD in an
`archlinux:base-devel` container. `arch-update.yml` runs `update.yml` with the
scripts in [`arch`](arch). The image is pinned by digest in both and has to be
bumped by hand, as Dependabot does not update images in workflows.

The package repo provides:

- `.github/scripts/upstream.sh latest`, which prints the newest upstream
  version.
- `.github/scripts/upstream.sh sums VERSION`, which prints a line per arch with
  the arch and the values of its `sha256sums_<arch>` array, separated by
  spaces. They should come from signed metadata, not from hashing the download.
- `.github/scripts/smoke-test.sh`, run as root after the package is installed.
  Optional.
- `keys/pgp/*.asc` for `validpgpkeys`. Optional.

```yaml
jobs:
  validate:
    uses: recmanj/github-workflows/.github/workflows/arch-ci.yml@<sha>
    permissions:
      contents: read
```

```yaml
jobs:
  update:
    uses: recmanj/github-workflows/.github/workflows/arch-update.yml@<sha>
    permissions:
      contents: write
      pull-requests: write
      actions: write
    with:
      body: 'Release notes: https://example.com/releases/{version}'
```

Dependencies that are not in the Arch repos are not installed. The build then
skips dependency checks and the package is installed with `-dd`.
