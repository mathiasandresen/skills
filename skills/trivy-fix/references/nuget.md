# NuGet (.NET)

Manifests: `*.csproj` `PackageReference`s, optionally `Directory.Packages.props` (central package management) and `packages.lock.json`. Trivy reads `packages.lock.json`, `*.deps.json`, and `packages.config`; with none present, `dotnet restore --use-lock-file` generates a lockfile to scan.

## Trace (step 3)

`dotnet list <project> package --vulnerable --include-transitive` and `dotnet nuget why <project> <pkg>` show the chain from the root `PackageReference`. Fix versions: trivy's "fixed version" or `dotnet package search <pkg> --exact-match --format json`.

## Fix (step 4)

1. Direct: bump `Version` on the `PackageReference` (or the `PackageVersion` in `Directory.Packages.props`).
2. Parent range allows the fix: NuGet resolves the lowest applicable version, so a lockfile refresh alone seldom moves a transitive; go to 4 unless the parent's range excludes the vulnerable version.
3. Root bump: check candidate root releases' dependencies, smallest step that pulls a fixed child, then bump the root.
4. Pin: add a direct `PackageReference` to the fixed transitive (with `Directory.Packages.props`, set `CentralPackageTransitivePinningEnabled` and add a `PackageVersion`). Comment why, so the pin audit can recognise it.

## Pin audit (step 7)

Remove one pin at a time in a scratch copy of the project, restore, and rescan. A pin is **needed** if the finding returns, **unneeded** if the resolve still lands at or above it.
