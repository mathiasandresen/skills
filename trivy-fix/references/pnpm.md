# pnpm

Lockfile: `pnpm-lock.yaml`. Pins: `pnpm.overrides` in `package.json` (or `overrides` in `pnpm-workspace.yaml`).

## Trace (step 3)

`pnpm why <pkg>` shows every chain to the root. Fix versions: trivy's "fixed version" or `pnpm view <pkg> versions --json`.

## Fix (step 4)

1. Direct: `pnpm add <pkg>@<version>` (add `-D` for a dev dependency; keep the existing range prefix style).
2. Parent range allows the fix: `pnpm update <pkg> --depth Infinity` limited to the lockfile (`--lockfile-only`).
3. Root bump: `pnpm view <root>@<version> dependencies`, smallest step that pulls a fixed child, then `pnpm add <root>@<version>`.
4. Scoped override with a parent selector: `"<parent>><pkg>": "<version>"`.

## Pin audit (step 7)

In a scratch dir outside the repo, copy `package.json` without overrides, no lockfile, run `pnpm install --lockfile-only --ignore-scripts`, scan `pnpm-lock.yaml` with the scan command's flags and ignorefile. Classify each override from what the scratch resolve shows.
