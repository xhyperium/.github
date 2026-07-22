# Callable reusable workflows

Canonical call path for GitHub Actions `uses:`:

`xhyperium/.github/.github/workflows/<name>.yml@main`

Browse-friendly docs and full examples live in the repo-root mirror:

**[`../../workflows/README.md`](../../workflows/README.md)**

YAML files in this directory **must** stay byte-identical to `workflows/*.yml`.
Sync with:

```bash
bash scripts/sync-workflows.sh
```

`meta-validate` CI fails if the two trees drift.
