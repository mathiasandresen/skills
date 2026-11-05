# skills

Claude Code skills.

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
