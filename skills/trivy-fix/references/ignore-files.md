# Ignorefiles

Trivy reads `.trivyignore` (one ID per line) or `.trivyignore.yaml` (structured), passed with `--ignorefile` or set in `trivy.yaml`. Use the format the project already has; propose `.trivyignore.yaml` only for a project with none, because it carries a `statement`.

## `.trivyignore.yaml` entry

```yaml
vulnerabilities:
  - id: CVE-XXXX-NNNN
    statement: We accept the risk, since <why unreachable>. <why no fix exists: latest version, blocking parent>.
```

- Follow the wording of the existing statements when there are any.
- Keep `: ` out of the statement; it breaks the YAML.
- Confirm with a scan run that the finding is suppressed and the file parses.

## `.trivyignore` entry

Add the ID on its own line with a `#` comment above carrying the same reasoning.
