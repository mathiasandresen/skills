---
name: gh-attach-screenshots
description: Upload local screenshots with GitHub CLI when adding images to a GitHub issue, pull request, or comment. Use for inline screenshots and before-and-after comparisons.
---

# Attach screenshots with GitHub CLI

Use `--attach` with `gh issue` or `gh pr` and the appropriate `create`, `edit`, or `comment` subcommand. GitHub CLI uploads each file and inserts its hosted URL into the Markdown sent to GitHub.

## Check the target

Pass `--repo OWNER/REPO` whenever the working directory could select a different repository. Use `edit` for the description and `comment` for a new comment.

Attachments require an authenticated account with push access on GitHub.com or GitHub Enterprise Cloud. The flag was introduced in `gh` 2.99.0. If the command reports an unknown flag, check `gh --version` and the subcommand’s `--help`. [GitHub CLI release notes](https://github.com/cli/cli/releases/tag/v2.99.0)

## Append a screenshot

```sh
gh pr edit 42 --repo OWNER/REPO \
  --attach './screenshots/settings.png#Settings panel with notifications enabled'
```

An `edit` with only attachment flags keeps the existing description and appends the images. Repeat `--attach` once per file; images with no matching reference in the body land at the end in flag order. Quote the whole `path#alt text` argument. Omitting the suffix makes the filename the alt text.

## Place screenshots within Markdown

Save the complete body as `pr-body.md` alongside the `screenshots/` directory. For an edit, start with the current description so that supplying a replacement body preserves its existing content.

```markdown
### Before

![Settings panel with clipped labels](./screenshots/before.png)

### After

![Settings panel with full labels visible](./screenshots/after.png)
```

Run this from the directory containing `pr-body.md` and `screenshots/`:

```sh
gh pr edit 42 --repo OWNER/REPO --body-file pr-body.md \
  --attach ./screenshots/before.png \
  --attach ./screenshots/after.png
```

`gh` replaces each matching local image path with its uploaded URL while preserving the image’s position and Markdown alt text. The same pattern works with `create` or `comment`. Supply a title when creating an issue or PR.

## Verify

Done when the read-back body contains a hosted image URL for every attached file and no local path remains:

```sh
gh pr view 42 --repo OWNER/REPO --json body -q .body | grep -n '!\[' 
```

(`gh issue view` for issues; for a comment, read it from `gh pr view --comments`.) A timeout after submission may still have posted: run this check before retrying, so nothing is duplicated.

[GitHub documentation for attaching files with GitHub CLI](https://docs.github.com/en/github-cli/github-cli/attaching-files-with-github-cli)
