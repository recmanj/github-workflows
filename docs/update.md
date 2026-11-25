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
from `update/<version>` exists yet, in any state and against any branch, it runs
`apply` and saves the diff of the tracked files.

`validate` applies that diff to a fresh checkout and runs `validate` with a
read-only token. It is the only job that should run anything from the new
version.

`publish` applies the same diff to another fresh checkout, commits it to
`update/<version>` and opens a pull request against the branch the workflow ran
on. Open pull requests from other `update/` branches against the same branch
are closed as superseded and their branches deleted. `publish` is the only job
with a write token, and it runs no command from the caller other than `setup`.

So the pull request contains exactly what `validate` tested. `apply` should
still not run anything from the new version, as `check` has a token, if only a
read-only one, and the diff it saves is what gets published. The diff is passed between the jobs compressed in a job output,
and has to stay under about 75 KB after gzip.

## Inputs

| Input | Default | |
| --- | --- | --- |
| `check` | required | Prints the version to update to, or nothing when up to date. |
| `apply` | required | Updates the files to `$VERSION`. |
| `validate` | | Tests the result of `apply`. |
| `setup` | | Runs at the start of every job, before the checkout. It runs in the job with the write token, so only use it to install tools. |
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
| `VERSION` | The new version, in `apply` and `validate`. |
| `WORKFLOWS_DIR` | This repository at the commit being run, in every command except `setup`. |

## Permissions

The calling job has to grant `contents: write` and `pull-requests: write` for
the pull request, and `actions: write` for `ci-workflow`. The repository also
needs "Allow GitHub Actions to create and approve pull requests" enabled.
