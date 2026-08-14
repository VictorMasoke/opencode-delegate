# opencode-delegate

A [Claude Code](https://claude.com/claude-code) skill that teaches Claude when and how to
delegate self-contained coding subtasks to [OpenCode](https://opencode.ai) — a separate,
locally-run open-source coding agent — so those subtasks run on OpenCode's own model and token
budget instead of yours.

## What this actually does (and doesn't)

This is **not** a proxy, router, or anything that reduces the token cost of a given prompt to
Claude. Nothing can do that — your usage on a request is a function of what's in that request's
context, not which network path it takes. Be skeptical of any tool that claims otherwise.

What this *does* do: it gives Claude a documented, safe pattern for shelling out to OpenCode —
a completely separate agent with its own model — for bounded, easily-verified work. Claude keeps
its own context clean and short, OpenCode does the mechanical work on a (often free-tier) model,
and Claude reviews the result before using it. You're not compressing tokens, you're moving
entire subtasks off Claude's plate.

Good fits: boilerplate, scaffolding, first-draft tests, repetitive mechanical edits.
Bad fits: anything needing conversation history, architectural judgment, or work you can't
verify by reading a diff. See [`skills/opencode-delegate/SKILL.md`](skills/opencode-delegate/SKILL.md)
for the full guidance Claude follows.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- [OpenCode](https://opencode.ai) installed and authenticated (`opencode models` should list at
  least one configured model)
- `jq` (only needed if you use the included wrapper script)

## Install

Copy the skill into your Claude Code skills directory:

```bash
git clone https://github.com/VictorMasoke/opencode-delegate.git
cp -r opencode-delegate/skills/opencode-delegate ~/.claude/skills/opencode-delegate
```

Restart Claude Code (or start a new session). Claude will pick up the skill automatically and
use it when a task looks like a good delegation candidate, or when you explicitly ask it to
"delegate this to opencode."

## Usage

Just ask, in a Claude Code session:

> Delegate writing the input-validation helpers to opencode.

Claude will check that OpenCode is installed, pick a model (preferring free ones), run the task
non-interactively via `opencode run`, and review the result before reporting back.

You can also invoke the included wrapper script directly, outside of Claude:

```bash
skills/opencode-delegate/scripts/opencode-run.sh "your prompt" /path/to/project opencode/deepseek-v4-flash-free
```

## Safety notes

OpenCode is run with `--auto`, which auto-approves file writes with no human in the loop for
that individual call. Only delegate work scoped to a directory you intend to review afterward
(a scratch dir, a feature branch, `git diff` before committing). Never point it at paths with
secrets or production config. Treat its output like a PR from an unfamiliar contributor — read
it before trusting it.

## License

MIT — see [LICENSE](LICENSE).
