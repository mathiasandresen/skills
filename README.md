# skills

Claude Code skills. Install one by copying or symlinking its folder into `~/.claude/skills/` (all projects) or `<project>/.claude/skills/` (one project).

## trivy-fix

Runs trivy, fixes what it flags, and reports what needs a decision. Detects the project's own trivy setup (scan script, ignorefile, test command), so it needs no configuration.

- Requires [trivy](https://trivy.dev/latest/getting-started/installation/).
- Ecosystems: npm (proven in daily use); pnpm, yarn, NuGet (written from the tools' documentation, best-effort). Others follow the same fix ladder with the ecosystem's native tools.
- Applies patch bumps unasked; minors, majors, and ignores wait for confirmation.

```sh
ln -s "$PWD/trivy-fix" ~/.claude/skills/trivy-fix
```
