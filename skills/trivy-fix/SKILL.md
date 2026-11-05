---
name: trivy-fix
description: Fix trivy vulnerability findings in any repo — detect how the project runs trivy, apply patch fixes silently, climb to the root dependency for transitive findings, check exposure before proposing an ignore, and report in up to three tables.
---

# Trivy fix

Scan repo deps, fix what trivy flags, without breaking stuff.

## Steps

1. **Detect** the setup; ask only where ambiguous:
   - `trivy --version`. Missing: stop and point to https://trivy.dev/latest/getting-started/installation/.
   - **Scan command**: the project's own (a `trivy` script in package.json, Makefile, or CI config; several candidates means ask). Otherwise `trivy filesystem . --scanners vuln`.
   - **Ignorefile**: the one the scan command passes, else `trivy.yaml`'s `ignorefile`, else `.trivyignore.yaml` / `.trivyignore` at the root.
   - **Ecosystems**: which lockfiles and manifests are in the findings.
   - **Test/build command**: from README, CI, or package scripts.
2. Run the scan command. Capture output. If clean, say so and skip to step 7.
3. Trace every finding: current version, fix version (trivy's "fixed version" or the registry), prod or dev, direct or transitive. For transitive, walk the chain up to the **root** (the entry in the manifest) and note each parent's declared range on the child. Group findings by ecosystem and read that ecosystem's reference first: [npm](references/npm.md), [pnpm](references/pnpm.md), [yarn](references/yarn.md), [NuGet](references/nuget.md). Other ecosystems follow the same ladder with their native tools.
4. Fix each finding with the simplest option that clears it, in this order:
   1. **Direct dependency**: bump it.
   2. **Transitive, a parent's range allows the fix**: refresh the lockfile only. No manifest change.
   3. **Transitive, ranges exclude the fix**: look for a newer **root** release that pulls a fixed child; take the smallest root step that does. Bump the root.
   4. **No root release helps**: scoped pin (override, resolution, or the ecosystem's equivalent).

   Class each change by the semver diff of the package that moves in the manifest (the root for option 3, otherwise the vulnerable package):
   - **Patch** (x.y.Z): apply now.
   - **Minor** (x.Y.z): table 3, untouched until confirmed.
   - **Major** (X.y.z): read the changelog or release notes, put the breaking changes in table 3, untouched until confirmed.
5. A finding with no simple, safe fix (a major, no fixed release, fix outside every range) gets an **exposure check** before it reaches table 3:
   - Read the advisory's `Description` (`trivy filesystem --scanners vuln -f json <lockfile>`, plus the scan command's flags) for the vulnerable function, option, or input.
   - Follow the chain from step 3: does it ship in a prod artifact or run only at build or dev time? Does repo code or config (`grep` imports, build config, call sites) reach the vulnerable condition? Can untrusted input reach it?
   - Verdict: **affected**, **not affected**, or **unsure** (treat as affected).
   - Not affected: recommend an ignorefile entry in table 3, in the format and statement style of [ignore-files](references/ignore-files.md).
   - A build-only tool listed under runtime dependencies is a fix too: recommend moving it to the dev group in table 3.
6. Re-run the scan command, then the test/build command. Every finding now sits in table 1 or table 3; a finding in neither is unfinished.
7. Audit pins: every pin the project carries (npm `overrides`, pnpm `overrides`, yarn `resolutions`, NuGet central version pins) must earn its place. The ecosystem reference holds the method; classify each:
   - **Needed**: a finding on its target package returns without it.
   - **Unneeded**: a pin-free resolve lands on a clean version at or above the pin.
   - **Unknown**: the pin forces a version outside the parent's declared range, or has no security motive (`git log -S'<entry>' -- <manifest>`). Keep it.

   Remove the unneeded entries, re-run the scan command to confirm still clean, list them in table 2.
8. Report with up to three tables; omit a table with no rows. A table-3 row is a decision for the user, so recommend one action per row.

   | # | Table | Columns |
   |---|-------|---------|
   | 1 | Auto-fixed | Package · from → to · how (bump / lockfile refresh / root bump / pin) |
   | 2 | Unpinned | Pin · why unneeded |
   | 3 | Needs your opinion | Package · fix needed (version, semver class) · finding (breaking changes or exposure verdict) · recommendation (bump / ignore / move to dev / keep) |

## Rules

- Only patch changes run unasked; minor, major, and every ignore or risk acceptance wait for the user.
- Root-cause the fix (the actual vulnerable dep or its root), and reach for the ignorefile only after the exposure check.
- Touch only deps trivy flagged.
- A transitive dependency (pulled in by another package, nothing in our code imports it) moves via lockfile refresh or scoped pin, because installing it by name adds it as a direct dependency, which lies about what we depend on.
- Scope a pin to the specific parent(s) that pulled the vulnerable version rather than the bare package name: a blanket pin rewrites every resolution of that name, including unrelated ones held to an incompatible major by other dependents.
- Create an ignorefile that does not exist yet only after the user agrees.
