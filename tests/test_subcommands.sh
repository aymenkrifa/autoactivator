# Black-box test suite for autoactivator subcommands.
#
# Run under both shells:
#   bash tests/test_subcommands.sh
#   zsh  tests/test_subcommands.sh
#
# Exits 0 if all tests pass, 1 otherwise.

# shellcheck disable=SC2164  # a failed fixture cd surfaces in the assertions
# shellcheck disable=SC2154  # block markers come from the sourced config

if [[ -n "$BASH_VERSION" ]]; then
  SHELL_NAME="bash"
elif [[ -n "$ZSH_VERSION" ]]; then
  SHELL_NAME="zsh"
  setopt SH_WORD_SPLIT 2>/dev/null
else
  echo "test_subcommands.sh: must be run under bash or zsh" >&2
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

assert_contains() {
  if [[ "$2" == *"$3"* ]]; then
    _pass "$1"
  else
    _fail "$1" "expected output to contain '$3'"
  fi
}

assert_not_contains() {
  if [[ "$2" != *"$3"* ]]; then
    _pass "$1"
  else
    _fail "$1" "expected output to NOT contain '$3'"
  fi
}

# --- Fixtures -----------------------------------------------------------------

# Fake HOME so doctor + uninstall target our fixtures, not the user's real rc.
# Stage the repo into the fake .autoactivator so `version` can read git data
# and the constants/activator paths exist where the config expects them.
FIXTURE_HOME="$(mktemp -d)"
mkdir -p "$FIXTURE_HOME/.autoactivator"
cp -r "$REPO_ROOT/." "$FIXTURE_HOME/.autoactivator/"
trap 'rm -rf "$FIXTURE_HOME"' EXIT

export HOME="$FIXTURE_HOME"
unset VIRTUAL_ENV VENV_ORIGINAL_DIR AUTOACTIVATOR_VENV_NAME
# Park cwd at the boundary so sourcing doesn't trigger an unexpected activation.
cd "$FIXTURE_HOME"
export AUTOACTIVATOR_BOUNDARY="$FIXTURE_HOME"

# shellcheck disable=SC1091
. "$REPO_ROOT/autoactivator_config.sh"

# Pick the rc file the current shell's doctor check will inspect.
if [[ -n "$ZSH_VERSION" ]]; then
  SHELL_RC="$FIXTURE_HOME/.zshrc"
else
  SHELL_RC="$FIXTURE_HOME/.bashrc"
fi

# --- Tests --------------------------------------------------------------------

echo "=== $SHELL_NAME ==="

# 1. help lists every dispatched command
help_out=$(autoactivator help)
for cmd in status doctor version update uninstall help; do
  assert_contains "help lists '$cmd'" "$help_out" "$cmd"
done

# 2. unknown command exits non-zero
if autoactivator nope >/dev/null 2>&1; then
  _fail "unknown command returns non-zero" "got exit 0"
else
  _pass "unknown command returns non-zero"
fi

# 3. version succeeds in a git repo
if autoactivator version >/dev/null 2>&1; then
  _pass "version succeeds in git repo"
else
  _fail "version succeeds in git repo" "got non-zero exit"
fi

# 4. status surfaces the cache-entries field
status_out=$(autoactivator status)
assert_contains "status shows cache field" "$status_out" "Cache entries:"
assert_contains "status shows boundary"    "$status_out" "Boundary:"

# 5. strip_block: removes the block and preserves surrounding content
rc_fixture="$FIXTURE_HOME/.test_rc_normal"
cat > "$rc_fixture" <<EOF
alias k=kubectl

$AUTOACTIVATOR_BLOCK_OPEN
source /home/x/.autoactivator/autoactivator_config.sh
$AUTOACTIVATOR_BLOCK_CLOSE

export FOO=bar
EOF
_autoactivator_strip_block "$rc_fixture" >/dev/null
result=$(cat "$rc_fixture")
assert_not_contains "strip removes open marker"   "$result" "$AUTOACTIVATOR_BLOCK_OPEN"
assert_contains    "strip preserves alias above"  "$result" "alias k=kubectl"
assert_contains    "strip preserves FOO below"    "$result" "FOO=bar"

# 6. strip_block: no block → no-op, returns 0
rc_fixture="$FIXTURE_HOME/.test_rc_noblock"
echo 'alias x=y' > "$rc_fixture"
_autoactivator_strip_block "$rc_fixture" >/dev/null
rv=$?
assert_eq "no-block strip returns 0" "$rv" "0"
result=$(cat "$rc_fixture")
assert_contains "no-block leaves file untouched" "$result" "alias x=y"

# 7. strip_block: malformed (open without close) → refuses, file untouched
rc_fixture="$FIXTURE_HOME/.test_rc_broken"
cat > "$rc_fixture" <<EOF
alias z=z

$AUTOACTIVATOR_BLOCK_OPEN
source /tmp/x
EOF
before=$(cat "$rc_fixture")
if _autoactivator_strip_block "$rc_fixture" >/dev/null 2>&1; then
  _fail "malformed block refused" "got exit 0"
else
  _pass "malformed block refused"
fi
after=$(cat "$rc_fixture")
assert_eq "malformed file untouched" "$after" "$before"

# 8. strip_block: writes a timestamped backup on successful strip
rc_fixture="$FIXTURE_HOME/.test_rc_backup"
cat > "$rc_fixture" <<EOF
$AUTOACTIVATOR_BLOCK_OPEN
source /tmp/x
$AUTOACTIVATOR_BLOCK_CLOSE
EOF
_autoactivator_strip_block "$rc_fixture" >/dev/null
# shellcheck disable=SC2012
backups=$(ls "$rc_fixture".pre-uninstall.* 2>/dev/null | wc -l)
if [[ "$backups" -ge 1 ]]; then
  _pass "backup file created"
else
  _fail "backup file created" "no .pre-uninstall.* file found beside $rc_fixture"
fi

# 9. doctor: passes when the shell's rc contains a well-formed block
cat > "$SHELL_RC" <<EOF
$AUTOACTIVATOR_BLOCK_OPEN
source $FIXTURE_HOME/.autoactivator/autoactivator_config.sh
$AUTOACTIVATOR_BLOCK_CLOSE
EOF
if autoactivator doctor >/dev/null 2>&1; then
  _pass "doctor passes with valid fixture"
else
  _fail "doctor passes with valid fixture" "got non-zero exit"
fi

# 10. uninstall (end-to-end via dispatcher): strips block from the shell rc
cat > "$SHELL_RC" <<EOF
alias keepme=ls

$AUTOACTIVATOR_BLOCK_OPEN
source $FIXTURE_HOME/.autoactivator/autoactivator_config.sh
$AUTOACTIVATOR_BLOCK_CLOSE
EOF
autoactivator uninstall >/dev/null 2>&1
result=$(cat "$SHELL_RC")
assert_not_contains "uninstall strips block from rc" "$result" "$AUTOACTIVATOR_BLOCK_OPEN"
assert_contains    "uninstall preserves other rc content" "$result" "alias keepme=ls"

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
