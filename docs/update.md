# update.yml

Opens a pull request when upstream has a new version. It does not know what
kind of repo it runs in. The caller passes shell commands that find the new
version and apply it.

```yaml
on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:

permissions:
  contents: read

jobs:
  update:
    uses: recmanj/github-workflows/.github/workflows/update.yml@<sha> # v1.0.0
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

## Jobs

`check` runs the `check` command. If it prints a version and no pull request
from `update/<version>` exists yet, in any state, it runs `pin`.

`validate` runs `apply` and then `validate` on a fresh checkout, with a
read-only token. It is the only job that should run anything from the new
version.

`publish` runs `apply` on another fresh checkout, commits the changed tracked
files to `update/<version>` and opens a pull request against the branch the
workflow ran on. The token is only used after `apply`, but `apply` must still
not run anything from the new version, since that could change what gets
committed.

`pin` is how `publish` makes sure it commits what `validate` tested: `check`
computes it once, both jobs get it, and `apply` should fail when upstream no
longer matches it.

## Inputs

| Input | Default | |
| --- | --- | --- |
| `check` | required | Prints the version to update to, or nothing when up to date. |
| `pin` | | Prints data about `$VERSION` that must not change before the pull request is opened, such as checksums. |
| `apply` | required | Updates the files to `$VERSION`. |
| `validate` | | Tests the result of `apply`. |
| `setup` | | Runs at the start of every job, before the checkout. |
| `runs-on` | `ubuntu-latest` | |
| `container` | | Image for every job. Pin it by digest. |
| `timeout-minutes` | `60` | Timeout of the `validate` job. |
| `title` | `Update to {version}` | Commit message and pull request title. |
| `body` | | Pull request body. |
| `ci-workflow` | | Workflow to run on the new branch. Pull requests opened with `GITHUB_TOKEN` do not trigger workflows, so without it the pull request gets no CI. |

`{version}` in `title` and `body` is replaced with the version.

The commands run with bash in the caller's checkout. They get these variables:

| Variable | |
| --- | --- |
| `VERSION` | The new version, in `pin`, `apply` and `validate`. |
| `PIN` | The output of `pin`, in `apply`. |
| `WORKFLOWS_DIR` | This repository at the commit being run, in every command except `setup`. |

## Permissions

The calling job has to grant `contents: write` and `pull-requests: write` for
the pull request, and `actions: write` for `ci-workflow`. The repository also
needs "Allow GitHub Actions to create and approve pull requests" enabled.
