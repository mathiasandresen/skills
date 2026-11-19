---
name: spec-to-prs
description: Build a spec's tickets as small reviewable PRs into one draft integration PR. Run by hand with the spec issue number.
disable-model-invocation: true
---

# Spec to PRs

Land a spec's tickets as **small PRs** into one **integration branch**, behind one **draft PR** into the default branch. The human reviews and merges every ticket PR; the run never merges for them.

## Setup

Read `docs/agents/issue-tracker.md`: it names the tracker, its CLI, and (under "Wayfinding operations", when present) how tickets, blocking edges and claims are expressed. Every tracker and PR operation below goes through it.

Stop and ask for `/setup-matt-pocock-skills` when that file is missing, or when the tracker has no PRs (local markdown): this skill needs a host that opens PRs.

Any PR verification rules the project documents (via `AGENTS.md` / `CLAUDE.md`, usually under `docs/agents/`) bind every ticket PR.

The tracker and its PRs are the only state. A re-run on the same spec resumes where the last one stopped.

## 1. Read the graph

Read the spec, its child tickets and their blocking edges. Classify each ticket from the tracker:

- **landed**: its PR is merged into the integration branch
- **in review**: its PR is open
- **frontier**: open, unclaimed, no PR, every blocker landed
- **waiting**: any blocker not landed

Done when every ticket has exactly one class.

## 2. Anchor the integration branch

Reuse `integration/<spec-slug>` and its draft PR when they exist. Otherwise branch it from the fresh default branch, push it, and open a draft PR into the default branch whose body links the spec and lists the tickets as a task list. Done when the draft PR URL is in hand.

## 3. Fan out the frontier

Delegate each **frontier** ticket at once to an implementer in its own worktree, in the background. Brief it with context pointers: spec, ticket, blocker PRs, exploration notes.

Each implementer:

1. Claims the ticket as the tracker doc describes.
2. Branches `integration/<spec-slug>/<ticket>-<slug>` from the current integration tip.
3. Builds the ticket test-first with `tdd`.
4. Rebases onto the integration tip, so the PR merges clean.
5. Opens a PR based on the integration branch, body written with `pr` when available, first line `Part of #<ticket>`, and verified per the project's PR verification rules against the integration base.
6. Comments the PR link on the ticket and reports the URL and CI result.

A ticket PR stays **small**: one ticket, one reviewable diff. The tracker closes a ticket when its PR lands, so the implementer leaves it open.

## 4. Hand back

When every implementer has reported, re-read the graph and report: PRs awaiting review, tickets now waiting on them, and the draft PR URL. Finish here and let the human review.

Merging a ticket PR makes its dependents **frontier**: the human re-runs `/spec-to-prs <spec>` to continue.

When every ticket has **landed**, run `code-review` on the integration branch against the default branch, post its findings on the draft PR, and leave the PR draft for the human to promote.

## Collisions

Parallel tickets that touch the same file or name are a graph bug: add a blocking edge between them and leave the later one **waiting**.
