---
name: opencode-delegate
description: Offload a self-contained coding subtask to a local OpenCode agent instead of doing it yourself, to save tokens/cost on your own conversation. Use when the user says things like "delegate this to opencode", "have opencode do this", "run this through opencode", "offload this", or when you're about to do bulky, mechanical, easily-verified work (boilerplate, scaffolding, repetitive file edits, a first draft of tests) that doesn't need your full conversation context.
---

# OpenCode delegate

Hand a self-contained subtask to [OpenCode](https://opencode.ai), a separate open-source coding
agent CLI, so it does the work on its own model instead of you doing it in this conversation.
OpenCode runs as its own process with its own model and its own token budget — work it does
doesn't cost you any of your context or usage. You only pay for the final result you read back.

This is **not** a way to reduce your own per-token cost on a given prompt (routing tricks and
proxies can't do that — your usage is a function of what's in your context, not which network
path a request takes). It genuinely helps by moving *entire subtasks* off your plate.

## When to use this

Good fits — self-contained, mechanical, easy to verify by reading the diff:
- Scaffolding a new file, config, or boilerplate module
- A first-draft implementation of a well-specified, isolated function
- Repetitive edits across files that follow a clear pattern
- Writing a first pass of tests for code that already exists
- Any task you could hand to a junior contributor with a short, self-contained spec

Bad fits — keep these yourself:
- Anything that needs the history/nuance of the current conversation (OpenCode starts cold —
  it has no memory of anything said here)
- Architectural decisions, or work where correctness is hard to verify by inspection
- Anything touching secrets, credentials, or destructive operations
- Tasks that need several back-and-forth clarifying turns (OpenCode is a fire-and-forget call
  per invocation, not a live collaborator)

If in doubt, do it yourself. Delegating something you then have to carefully re-check and fix
line-by-line costs more than just doing it.

## Prerequisites

OpenCode must already be installed and authenticated on the user's machine:

```bash
which opencode && opencode --version
opencode models          # confirms it's configured; note which models are free
```

If `opencode` isn't found, or `opencode models` returns nothing, stop and tell the user —
don't try to install or configure it for them without asking; auth is tied to their accounts.

## Running a task

Invoke it non-interactively with `opencode run`. Key flags:

- `--model <provider/model>` — pick one, ideally a free one from `opencode models`
- `--format json` — structured event stream (recommended when you need to parse the result
  programmatically); `--format default` for readable output when you're just eyeballing it
- `--auto` — auto-approves file writes/tool calls with no prompt. **Required** for headless use
  (there's no TTY to approve permissions interactively) but means OpenCode can write/modify
  files without a human in the loop — see Safety below.
- `--dir <path>` — scope it to a specific working directory
- `-f/--file <path>` — attach a file for it to read
- `--title <text>` — label the session

```bash
opencode run "Write a Python function that validates an email address with a regex. \
Save it to validators.py with a docstring and one usage example." \
  --model opencode/deepseek-v4-flash-free \
  --format json \
  --auto \
  --dir /path/to/project
```

Because OpenCode has no memory of this conversation, **write the prompt as a fully
self-contained spec**: include the relevant file paths, the exact behavior wanted, and any
constraints. Don't say "do the thing we discussed" — it has no idea what that means.

### Parsing `--format json` output

Output is one JSON object per line (a streamed event log). The parts you care about:

- `"type":"text"` events — the model's text output is in `.part.text`
- `"type":"step_finish"` events — `.part.tokens` (their token usage, not yours) and `.part.cost`
  (should be `0` on free models)

A quick way to pull just the final text:

```bash
opencode run "..." --model opencode/deepseek-v4-flash-free --format json --auto \
  | jq -rs '[.[] | select(.type=="text")] | last | .part.text'
```

For tasks where OpenCode is writing/editing files directly, you often don't need to parse the
text at all — just inspect the files it touched afterward (`git diff`, `cat`, etc.) the same way
you'd review any other change before trusting it.

## Safety

- `--auto` means unattended file writes. Only point it at a directory you're prepared to review
  afterward — a scratch dir, a feature branch, or a repo you'll diff before committing. Never
  point it at a path with secrets, credentials, or production config.
- Treat OpenCode's output like you'd treat a PR from an unfamiliar contributor: read the diff,
  don't blindly merge it forward, especially before running or committing it.
- If a task involves anything destructive (deleting data, force-pushing, modifying
  infrastructure), do not delegate it — do it yourself with the normal care that requires.

## Choosing a model

Run `opencode models` to see what's configured. Prefer free-tier models
(commonly suffixed `-free` in this setup) for routine delegation — that's the entire point of
offloading: the work costs the user nothing extra. Reserve paid/larger models on the OpenCode
side for subtasks that are worth the higher quality.

## Example: reporting back to the user

After a delegated task finishes, tell the user plainly what happened — this is delegation, not
magic:

> Delegated to OpenCode (`deepseek-v4-flash-free`, free tier). It wrote `validators.py`.
> Reviewed the diff — looks correct. [show diff or summary]
