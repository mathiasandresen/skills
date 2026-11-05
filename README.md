# skills

Skills for coding agents.

## Install

With [skills.sh](https://skills.sh):

```sh
npx skills add mathiasandresen/skills
```

Pick the skills and agents in the prompt. To install a single skill, add `--skill trivy-fix`.

Manually: copy or symlink a skill's folder into `~/.claude/skills/` (all projects) or `<project>/.claude/skills/` (one project).

## trivy-fix

Runs trivy, fixes what it flags, and reports what needs a decision. Detects the project's own trivy setup (scan script, ignorefile, test command), so it needs no configuration.

- Requires [trivy](https://trivy.dev/latest/getting-started/installation/).
- Ecosystems: npm (proven in daily use); pnpm, yarn, NuGet (written from the tools' documentation, best-effort). Others follow the same fix ladder with the ecosystem's native tools.
- Applies patch bumps unasked; minors, majors, and ignores wait for confirmation.

## share-files

Upload and download requested files through a locally configured Copyparty folder. Requires macOS and Xcode Command Line Tools. Server URLs belong in `~/.config/share-files/config.json`; credentials stay in macOS Keychain. No server or credentials are bundled.

Install with `npx skills add mathiasandresen/skills --skill share-files`. Run `sh tests/share-files.sh` on macOS to validate configuration and URL boundaries without network or Keychain access.
