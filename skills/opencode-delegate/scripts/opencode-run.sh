#!/usr/bin/env bash
# Thin wrapper around `opencode run` for headless delegation.
#
# Usage:
#   opencode-run.sh <prompt> [dir] [model]
#
# Prints the model's final text response to stdout.
# Requires: opencode (https://opencode.ai), jq

set -euo pipefail

if ! command -v opencode >/dev/null 2>&1; then
  echo "error: opencode is not installed or not on PATH" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required to parse opencode's json output" >&2
  exit 1
fi

PROMPT="${1:?usage: opencode-run.sh <prompt> [dir] [model]}"
DIR="${2:-$PWD}"
MODEL="${3:-}"

MODEL_ARGS=()
if [[ -n "$MODEL" ]]; then
  MODEL_ARGS=(--model "$MODEL")
fi

opencode run "$PROMPT" \
  "${MODEL_ARGS[@]}" \
  --format json \
  --auto \
  --dir "$DIR" \
  | jq -rs '[.[] | select(.type=="text")] | last | .part.text // empty'
