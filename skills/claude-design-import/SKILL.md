---
name: claude-design-import
description: Import a Claude Design artifact through a Claude Haiku subagent when Codex cannot access a user-provided claude.ai/code/artifact/<id> URL. Requires T3 Code orchestration; stops if Claude delegation or artifact access is unavailable.
---

# Claude Design import

Use this workflow when the user's task needs an existing Claude Design artifact and Codex lacks direct access. If Codex can already retrieve the artifact, use that access directly.

## 1. Check delegation

Discover T3's `orchestrator_capabilities` and `delegate_task` tools. If either is unavailable, report that this import requires T3 Code with Claude subagents and stop the artifact-dependent task.

Use `orchestrator_capabilities` once per thread (reuse an existing result). Include `search: "haiku"` when making the call so Haiku models appear in the catalog. Select a Claude provider with both `canRunChildTask` and `canRunCrossProviderChildTask` enabled and an available Haiku model. Resolve provider and model IDs from the catalog rather than hardcoding them. Repeat discovery only after an error or a user-named provider change, following T3's orchestration instructions.

If no eligible Claude Haiku target is available, state the unavailable provider or model and stop. Use no substitute provider, model, CLI, or browser workaround.

## 2. Request the export

Call `delegate_task` with:

- `target.providerInstanceId` and `target.model`: the selected catalog IDs.
- `target.options: {}`: clear inherited Codex options.
- `role: "research"`, `mode: "wait"`, `isolation: "shared"`.
- `task`: a self-contained export brief containing the exact artifact URL, the user's intended use, the parent's absolute checkout path, and the instructions below. The child receives no parent history.

Export brief:

> Retrieve the existing Claude Design artifact at **[URL]** for **[intended use]**. Work in **[checkout path]** and save exports under `.design-references/[artifact-id]/` within that checkout. Treat the artifact ID as one safe directory component.
>
> Discover and use your authenticated Claude Design/artifact tools. Having a Claude model does not itself guarantee these tools or access to this artifact. If the tools are absent, access is denied, or the artifact cannot be retrieved, report the specific failure and stop. Do the work yourself without further delegation.
>
> Export the actual artifact. Prefer original HTML with available styles, scripts, and assets when source inspection or implementation is needed. Prefer screenshots when visual reference is sufficient or source export is unavailable. Export both when screenshots materially clarify the rendered HTML. Capture the relevant screens/states and record screenshot viewport dimensions. Preserve available original source and assets; identify missing dependencies or assets.
>
> Keep the original artifact unchanged and private. Export only; do not recreate the design or implement the user's application.
>
> Write `README.md` beside the exports with the source URL, retrieved version if available, exported file paths, captured screens/states, design intent supported by the artifact, and export limitations. Distinguish original source from rendered captures and any export packaging changes. Report success, partial export, or failure, with absolute paths to usable files and any gaps.

Follow the delegation response's `next` instruction. If completion will wake the parent, end the turn and resume on completion instead of polling. A timeout is not a failed export or permission to start a duplicate child.

## 3. Verify and use

After completion, check that the reported exports exist in the parent's checkout and contain the retrieved artifact. Read the README and HTML/source; open exported screenshots with an image-viewing tool. A README alone, a login page, or the child's summary is not a usable export.

Use the verified files as the implementation reference, accounting for stated limitations. A partial export is usable only when it covers the user's required design; report any remaining gaps. If retrieval failed or required content is missing, explain the blocker and stop the artifact-dependent task. Never fill retrieval gaps with a guessed design.
