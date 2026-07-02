# Black-box test suite for activator.sh.
#
# Run under both shells:
#   bash tests/test_activator.sh
#   zsh  tests/test_activator.sh
#
# Exits 0 if all tests pass, 1 otherwise.

if [[ -n "$BASH_VERSION" ]]; then
  SHELL_NAME="bash"
elif [[ -n "$ZSH_VERSION" ]]; then
  SHELL_NAME="zsh"
  setopt SH_WORD_SPLIT 2>/dev/null
else
  echo "test_activator.sh: must be run under bash or zsh" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PASS=0
FAIL=0
FAIL_LINES=()

_pass() { printf '  PASS: %s\n' "$1"; PASS=$((PASS+1)); }
_fail() {
  printf '  FAIL: %s — %s\n' "$1" "$2"
  FAIL=$((FAIL+1))
  FAIL_LINES+=("$1: $2")
}

assert_eq() {
  if [[ "$2" == "$3" ]]; then
    _pass "$1"
  else
    _fail "$1" "expected '$3', got '$2'"
  fi
}

# --- Fixtures -----------------------------------------------------------------

FIXTURE_ROOT="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

make_activate() {
  # $1 = venv directory; creates bin/activate that exports VIRTUAL_ENV and
  # defines a deactivate function compatible with both shells.
  mkdir -p "$1/bin"
  cat > "$1/bin/activate" <<EOF
deactivate() { unset VIRTUAL_ENV; unset -f deactivate 2>/dev/null; }
export VIRTUAL_ENV="$1"
EOF
}

# projA: a single .venv at the project root, plus a nested subdir
mkdir -p "$FIXTURE_ROOT/projA/src/deep"
make_activate "$FIXTURE_ROOT/projA/.venv"

# projB: a second project to test switching
make_activate "$FIXTURE_ROOT/projB/.venv"

# projConda: only a conda-style env (has bin/conda) — should not activate
make_activate "$FIXTURE_ROOT/projConda/cenv"
touch "$FIXTURE_ROOT/projConda/cenv/bin/conda"

# projMulti: both .venv and an alphabetically-earlier directory
make_activate "$FIXTURE_ROOT/projMulti/.venv"
make_activate "$FIXTURE_ROOT/projMulti/aaa_env"

# projVenvEnv: venv and env both present — venv has higher priority
make_activate "$FIXTURE_ROOT/projVenvEnv/venv"
make_activate "$FIXTURE_ROOT/projVenvEnv/env"

# projCustom: only a non-standard name, exercises the override
make_activate "$FIXTURE_ROOT/projCustom/myenv"

# Somewhere outside all projects
mkdir -p "$FIXTURE_ROOT/outside"

# --- Source activator.sh ------------------------------------------------------

export AUTOACTIVATOR_BOUNDARY="$FIXTURE_ROOT"
cd "$FIXTURE_ROOT/outside"
# shellcheck disable=SC1091
source "$REPO_ROOT/activator.sh"

# True when this shell has the associative-array cache (zsh, or bash >= 4 —
# macOS ships bash 3.2, where the activator runs cacheless).
have_cache() {
  [[ -n "$ZSH_VERSION" ]] || ((${BASH_VERSINFO[0]:-0} >= 4))
}

reset_state() {
  if command -v deactivate >/dev/null 2>&1; then
    deactivate
  fi
  unset VIRTUAL_ENV VENV_ORIGINAL_DIR AUTOACTIVATOR_VENV_NAME
  if [[ -n "$ZSH_VERSION" ]]; then
    _AUTOACTIVATOR_CACHE=()
  elif have_cache; then
    unset _AUTOACTIVATOR_CACHE
    declare -gA _AUTOACTIVATOR_CACHE
  fi
  cd "$FIXTURE_ROOT/outside"
}

# --- Tests --------------------------------------------------------------------

echo "=== $SHELL_NAME ==="

# 1. Activate when entering a project root
reset_state
cd "$FIXTURE_ROOT/projA"
_check_for_venv
assert_eq "activate on entering project" "$VIRTUAL_ENV" "$FIXTURE_ROOT/projA/.venv"

# 2. Stay activated when cd'ing into a subdirectory of the same project
cd "$FIXTURE_ROOT/projA/src"
_check_for_venv
assert_eq "stay active in subdir"        "$VIRTUAL_ENV" "$FIXTURE_ROOT/projA/.venv"

# 3. Walk up parents to find venv from a deeply nested cwd
reset_state
cd "$FIXTURE_ROOT/projA/src/deep"
_check_for_venv
assert_eq "walk up parents from nested"  "$VIRTUAL_ENV" "$FIXTURE_ROOT/projA/.venv"

# 4. Deactivate when leaving the project tree
cd "$FIXTURE_ROOT/outside"
_check_for_venv
assert_eq "deactivate on leaving tree"   "$VIRTUAL_ENV" ""

# 5. Skip conda-style envs (no activation)
reset_state
cd "$FIXTURE_ROOT/projConda"
_check_for_venv
assert_eq "skip conda env"               "$VIRTUAL_ENV" ""

# 6. Switch between projects
reset_state
cd "$FIXTURE_ROOT/projA"; _check_for_venv
cd "$FIXTURE_ROOT/projB"; _check_for_venv
assert_eq "switch projects"              "$VIRTUAL_ENV" "$FIXTURE_ROOT/projB/.venv"

# 7. Priority: .venv beats an alphabetically-earlier venv
reset_state
cd "$FIXTURE_ROOT/projMulti"
_check_for_venv
assert_eq "priority .venv over aaa_env"  "$VIRTUAL_ENV" "$FIXTURE_ROOT/projMulti/.venv"

# 8. Priority: venv beats env
reset_state
cd "$FIXTURE_ROOT/projVenvEnv"
_check_for_venv
assert_eq "priority venv over env"       "$VIRTUAL_ENV" "$FIXTURE_ROOT/projVenvEnv/venv"

# 9. AUTOACTIVATOR_VENV_NAME override picks the named directory
reset_state
export AUTOACTIVATOR_VENV_NAME=aaa_env
cd "$FIXTURE_ROOT/projMulti"
_check_for_venv
assert_eq "override picks named venv"    "$VIRTUAL_ENV" "$FIXTURE_ROOT/projMulti/aaa_env"

# 10. Override falls through to priority list when the named dir is missing
reset_state
export AUTOACTIVATOR_VENV_NAME=does_not_exist
cd "$FIXTURE_ROOT/projMulti"
_check_for_venv
assert_eq "override falls through"       "$VIRTUAL_ENV" "$FIXTURE_ROOT/projMulti/.venv"

# 11. Override activates a non-standard venv name
reset_state
export AUTOACTIVATOR_VENV_NAME=myenv
cd "$FIXTURE_ROOT/projCustom"
_check_for_venv
assert_eq "override activates myenv"     "$VIRTUAL_ENV" "$FIXTURE_ROOT/projCustom/myenv"

# 12. Idempotent hook registration: re-sourcing does not double-register
reset_state
# shellcheck disable=SC1091
source "$REPO_ROOT/activator.sh"
# shellcheck disable=SC1091
source "$REPO_ROOT/activator.sh"
if [[ -n "$ZSH_VERSION" ]]; then
  count=$(print -l ${chpwd_functions} | grep -c '^_check_for_venv$')
  assert_eq "zsh hook registered once"   "$count" "1"
elif [[ -n "$BASH_VERSION" ]]; then
  count=$(grep -o '_autoactivator_bash_chpwd' <<<"$PROMPT_COMMAND" | wc -l)
  assert_eq "bash hook registered once"  "$count" "1"
fi

# 13. Cache is populated after an activation (zsh and bash >= 4)
reset_state
if have_cache; then
  cd "$FIXTURE_ROOT/projA"
  _check_for_venv
  assert_eq "cache populated on activation" "${#_AUTOACTIVATOR_CACHE[@]}" "1"
fi

# 14. A venv created after a directory was first visited is picked up
reset_state
mkdir -p "$FIXTURE_ROOT/projLate"
cd "$FIXTURE_ROOT/projLate"
_check_for_venv
make_activate "$FIXTURE_ROOT/projLate/.venv"
cd "$FIXTURE_ROOT/outside"; _check_for_venv
cd "$FIXTURE_ROOT/projLate"; _check_for_venv
assert_eq "venv created after first visit" "$VIRTUAL_ENV" "$FIXTURE_ROOT/projLate/.venv"

# 15. A stale cache entry (venv gone) falls back to the walk on the same cd
reset_state
if have_cache; then
  _AUTOACTIVATOR_CACHE[$FIXTURE_ROOT/projA]="$FIXTURE_ROOT/gone-venv"
  cd "$FIXTURE_ROOT/projA"
  _check_for_venv
  assert_eq "stale cache entry recovers"   "$VIRTUAL_ENV" "$FIXTURE_ROOT/projA/.venv"
fi

# --- Summary ------------------------------------------------------------------

echo
echo "$SHELL_NAME: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
  echo "Failures:"
  for line in "${FAIL_LINES[@]}"; do
    echo "  - $line"
  done
  exit 1
fi
exit 0
