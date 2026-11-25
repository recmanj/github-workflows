# arch-update.yml

[`update.yml`](update.md) for a PKGBUILD repo. It runs in an
`archlinux:base-devel` container, sets `pkgver` and the checksums in the
PKGBUILD, regenerates `.SRCINFO` and validates the result like
[`arch-ci.yml`](arch-ci.md).

```yaml
on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:

permissions:
  contents: read

jobs:
  update:
    uses: recmanj/github-workflows/.github/workflows/arch-update.yml@<sha> # v1.0.0
    permissions:
      contents: write
      pull-requests: write
      actions: write
    with:
      body: 'Release notes: https://example.com/releases/{version}'
```

## Inputs

| Input | Default | |
| --- | --- | --- |
| `body` | | Pull request body. `{version}` is replaced with the version. |
| `ci-workflow` | `ci.yml` | Workflow to run on the new branch. |

## Package repo

The repo needs `.github/scripts/upstream.sh` with two commands:

`upstream.sh latest` prints the newest upstream version.

`upstream.sh sums VERSION` prints the checksums of that version, a line per
arch with the arch followed by the values of its `sha256sums_<arch>` array:

```
x86_64 f8b5489babb2b67fb49dc8ed891b9e423078831dbb3ad276fae1e5c6254731fb
aarch64 d3f8f8ddce79d4ca4560d006744c76bddf2e9ff1184057d46618937b94ad1cd6
```

The checksums should come from signed metadata, not from hashing the download.

The update is only proposed when the version is newer than `pkgver` in
`.SRCINFO`, compared with `vercmp`. `pkgrel` is reset to 1.
