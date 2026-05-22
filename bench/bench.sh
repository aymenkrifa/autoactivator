#!/usr/bin/env bash
# Measure the per-cd cost of the autoactivator hook.
#
# Run under each shell:
#   bash bench/bench.sh
#   zsh  bench/bench.sh
#
# Override iteration count with BENCH_ITERATIONS (default: 1000).

N="${BENCH_ITERATIONS:-1000}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ACTIVATOR="$SCRIPT_DIR/../activator.sh"

if [[ ! -f "$ACTIVATOR" ]]; then
  echo "bench: cannot find activator.sh at $ACTIVATOR" >&2
  exit 1
fi

# Don't touch the host shell's active venv (if any).
unset VIRTUAL_ENV VENV_ORIGINAL_DIR

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/myproject/.venv/bin"
: > "$TMP/myproject/.venv/bin/activate"   # empty fake; sourcing is a no-op

# Bound the walk so we measure only the work the hook actually does.
export AUTOACTIVATOR_BOUNDARY="$TMP"

# shellcheck source=/dev/null
source "$ACTIVATOR"

cd "$TMP/myproject" || exit 1

# Warm the OS-level filesystem cache.
_check_for_venv

if [[ -n "${ZSH_VERSION:-}" ]]; then
  SHELL_NAME=zsh
else
  SHELL_NAME=bash
fi

start=$(date +%s.%N)
for ((i = 0; i < N; i++)); do
  unset "_AUTOACTIVATOR_CACHE[$PWD]" 2>/dev/null
  _check_for_venv
done
end=$(date +%s.%N)

avg=$(awk -v s="$start" -v e="$end" -v n="$N" \
  'BEGIN { printf "%.6f", (e - s) / n }')

printf '%s: %s s/cd (cold cache, mean over %d runs)\n' "$SHELL_NAME" "$avg" "$N"
