# npm

Lockfile: `package-lock.json`. Pins: `overrides` in `package.json`.

## Trace (step 3)

Walk `package-lock.json` for the finding's package: every `node_modules/…` path shows the chain. Fix versions: trivy's "fixed version" or `npm view <pkg> versions --json`. `npm ls <pkg>` shows who pulls it.

## Fix (step 4)

1. Direct: `npm install <pkg>@<version>`.
2. Parent range allows the fix: `npm update <pkg> --package-lock-only --ignore-scripts`.
3. Root bump: `npm view <root>@<version> dependencies` for each candidate release; take the smallest step that pulls a fixed child, then `npm install <root>@<version>`.
4. Scoped `overrides`, e.g. `{"cosmiconfig": {"js-yaml": "4.3.2"}}`, not a bare `{"js-yaml": "4.3.2"}`.

Changelogs for majors: `npm view <pkg> repository.url`.

`npm install <pkg>@<version>` writes a caret range. If the dep was pinned exact (no `^`/`~`) before the bump, check `package.json` afterwards and strip the caret.

Trivy skips dev dependencies, so a finding that survives is prod, or a build tool listed under `dependencies` (move it to `devDependencies`).

## Pin audit (step 7)

In a scratch dir outside the repo, copy `package.json` without `overrides`, no lockfile. Run `npm install --package-lock-only --ignore-scripts`, then scan that lockfile with the scan command's flags and ignorefile (`trivy filesystem --scanners vuln --ignorefile <repo>/<ignorefile> package-lock.json`). Classify each override from what the scratch resolve shows.
