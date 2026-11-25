# github-workflows

Reusable GitHub Actions workflows.

| Workflow | Description |
| --- | --- |
| [update.yml](docs/update.md) | Opens a pull request when upstream has a new version. Generic, the caller passes the commands. |
| [arch-update.yml](docs/arch-update.md) | `update.yml` set up for a PKGBUILD repo. |
| [arch-ci.yml](docs/arch-ci.md) | Lints, builds and installs a PKGBUILD. |

Pin them to a commit, with the tag in a comment so that Dependabot can update
the pin:

```yaml
uses: recmanj/github-workflows/.github/workflows/update.yml@<sha> # v1.0.0
```
