# yarn

Lockfile: `yarn.lock`. Pins: `resolutions` in `package.json`.

## Trace (step 3)

`yarn why <pkg>` shows chains to the root. Fix versions: trivy's "fixed version" or `yarn npm info <pkg>` (Berry) / `npm view <pkg> versions --json` (Classic).

## Fix (step 4)

1. Direct: `yarn add <pkg>@<version>` (`-D` for dev; keep the existing range prefix style).
2. Parent range allows the fix: Berry `yarn up -R <pkg>`; Classic delete the `<pkg>` entries from `yarn.lock` and run `yarn install --ignore-scripts`.
3. Root bump: check candidate root releases' dependencies, smallest step that pulls a fixed child, then `yarn add <root>@<version>`.
4. Scoped `resolutions` with a parent path: `"<parent>/<pkg>": "<version>"`.

## Pin audit (step 7)

In a scratch dir outside the repo, copy `package.json` without `resolutions`, no lockfile, run `yarn install --mode update-lockfile` (Berry) or `yarn install --ignore-scripts` (Classic), scan `yarn.lock` with the scan command's flags and ignorefile. Classify each resolution from what the scratch resolve shows.
