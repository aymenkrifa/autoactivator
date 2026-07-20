# Black-box test suite for setup.sh (the installer).
#
# Bash-only: setup.sh always runs under bash (piped installs execute it with
# `| bash`), so there is no zsh variant of this suite. CI also runs it under
# macOS's system /bin/bash, so keep it bash-3.2-clean — no associative
# arrays, no ${var,,}.
#
#   bash tests/test_setup.sh
#
# Exits 0 if all tests pass, 1 otherwise.
#
# Everything is hermetic: installs clone from a local fixture repo
# (AUTOACTIVATOR_REPO_URL) or unpack a local tarball over file://
# (AUTOACTIVATOR_TARBALL_URL) into throwaway $HOMEs — no network.

# shellcheck disable=SC2154  # block markers come from the sourced constants

if [ -z "$BASH_VERSION" ]; then
  echo "test_setup.sh: must be run under bash" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETUP="$REPO_ROOT/setup.sh"

# shellcheck source=../_constants.sh disable=SC1091
. "$REPO_ROOT/_constants.sh"

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

assert_file() {
  if [[ -e "$2" ]]; then
    _pass "$1"
  else
    _fail "$1" "expected '$2' to exist"
  fi
}

assert_no_file() {
  if [[ ! -e "$2" ]]; then
    _pass "$1"
  else
    _fail "$1" "expected '$2' to NOT exist"
  fi
}

# --- Fixtures -----------------------------------------------------------------

FIXTURE_ROOT="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

# Hermetic source repo: the current worktree (including uncommitted changes)
# committed onto a `main` branch, so clone/pull work regardless of the state
# of the checkout running the tests.
SRC_REPO="$FIXTURE_ROOT/src-repo"
mkdir -p "$SRC_REPO"
cp -r "$REPO_ROOT/." "$SRC_REPO/"
rm -rf "$SRC_REPO/.git"
git -C "$SRC_REPO" init -q
git -C "$SRC_REPO" checkout -q -b main
git -C "$SRC_REPO" add -A
git -C "$SRC_REPO" -c user.name=test -c user.email=test@example.com \
    -c commit.gpgsign=false commit -qm fixture

# Local tarball mimicking the GitHub codeload layout (single top-level dir).
TARBALL="$FIXTURE_ROOT/autoactivator-main.tar.gz"
mkdir -p "$FIXTURE_ROOT/stage/autoactivator-main"
cp -r "$SRC_REPO/." "$FIXTURE_ROOT/stage/autoactivator-main/"
rm -rf "$FIXTURE_ROOT/stage/autoactivator-main/.git"
tar -czf "$TARBALL" -C "$FIXTURE_ROOT/stage" autoactivator-main

# PATH sandbox without git, to force the tarball fallback. Symlinks to the
# real tools setup.sh needs; gzip is spelled out because GNU tar execs it
# for -z. The wget branch of the downloader has no coverage here (wget can't
# fetch file:// URLs) — it's kept honest by shellcheck only.
STUB_BIN="$FIXTURE_ROOT/stub-bin"
mkdir -p "$STUB_BIN"
for tool in bash uname curl tar gzip mktemp grep cat cp rm mkdir mv touch basename; do
  src="$(command -v "$tool" 2>/dev/null)" || continue
  ln -s "$src" "$STUB_BIN/$tool"
done

# Same sandbox minus any download tool, for the "nothing available" failure.
STUB_BIN_NODL="$FIXTURE_ROOT/stub-bin-nodl"
mkdir -p "$STUB_BIN_NODL"
for tool in bash uname tar gzip mktemp grep cat cp rm mkdir mv touch basename; do
  src="$(command -v "$tool" 2>/dev/null)" || continue
  ln -s "$src" "$STUB_BIN_NODL/$tool"
done

new_home() {
  NEW_HOME="$FIXTURE_ROOT/$1"
  mkdir -p "$NEW_HOME"
}

# Run setup.sh against a throwaway HOME with the fixture repo, capturing
# stdout+stderr. Cases needing more env (SHELL, PATH, tarball URL) inline
# the invocation instead.
run_setup() {
  local h="$1"; shift
  HOME="$h" AUTOACTIVATOR_REPO_URL="$SRC_REPO" "$BASH" "$SETUP" "$@" 2>&1
}

# --- Tests --------------------------------------------------------------------

echo "=== setup.sh ==="

# 1. Git install: explicit shell, fresh HOME without an rc file
new_home home-git
out=$(run_setup "$NEW_HOME" bash); rv=$?
assert_eq   "git install exits 0" "$rv" "0"
assert_file "git install produces a git checkout" "$NEW_HOME/.autoactivator/.git"
assert_file "missing rc auto-created" "$NEW_HOME/.bashrc"
assert_contains "rc gained the activator block" "$(cat "$NEW_HOME/.bashrc")" "$AUTOACTIVATOR_BLOCK_OPEN"
assert_contains "finish message names the rc" "$out" "source ~/.bashrc"

# 2. Re-run is idempotent: takes the pull path, still exactly one block
out=$(run_setup "$NEW_HOME" bash); rv=$?
assert_eq "re-run exits 0" "$rv" "0"
assert_contains "re-run takes the pull path" "$out" "Pulling latest"
cnt=$(grep -cF "$AUTOACTIVATOR_BLOCK_OPEN" "$NEW_HOME/.bashrc")
assert_eq "re-run keeps exactly one block" "$cnt" "1"

# 3. Zero-arg auto-detection from $SHELL (zsh is present in CI and on macOS)
if command -v zsh >/dev/null 2>&1; then
  new_home home-autodetect
  out=$(HOME="$NEW_HOME" AUTOACTIVATOR_REPO_URL="$SRC_REPO" \
        SHELL="$(command -v zsh)" "$BASH" "$SETUP" 2>&1); rv=$?
  assert_eq "zero-arg install exits 0" "$rv" "0"
  assert_contains "detection message names zsh" "$out" "detected zsh"
  assert_contains "zshrc gained the activator block" "$(cat "$NEW_HOME/.zshrc")" "$AUTOACTIVATOR_BLOCK_OPEN"
  assert_no_file "bashrc untouched by zsh-only install" "$NEW_HOME/.bashrc"
else
  echo "  SKIP: zsh not installed — zero-arg detection case not run"
fi

# 4. Zero-arg with no detectable shell fails with guidance
new_home home-undetectable
out=$(HOME="$NEW_HOME" AUTOACTIVATOR_REPO_URL="$SRC_REPO" \
      SHELL=/usr/bin/fish "$BASH" "$SETUP" 2>&1); rv=$?
if [[ "$rv" -ne 0 ]]; then
  _pass "undetectable shell exits non-zero"
else
  _fail "undetectable shell exits non-zero" "got exit 0"
fi
assert_contains "undetectable shell explains itself" "$out" "Could not auto-detect"

# 5. Pre-existing rc content preserved + one-time snapshot backup
new_home home-preserve
echo 'alias keepme=ls' > "$NEW_HOME/.bashrc"
run_setup "$NEW_HOME" bash >/dev/null
rc_content=$(cat "$NEW_HOME/.bashrc")
assert_contains "existing rc content preserved" "$rc_content" "alias keepme=ls"
assert_contains "block appended to existing rc" "$rc_content" "$AUTOACTIVATOR_BLOCK_OPEN"
assert_file "pre-install backup created" "$NEW_HOME/.bashrc.pre-autoactivator"
assert_not_contains "backup is the pre-install snapshot" \
  "$(cat "$NEW_HOME/.bashrc.pre-autoactivator")" "$AUTOACTIVATOR_BLOCK_OPEN"

# 6. Tarball install when git is absent from PATH
new_home home-tarball
out=$(HOME="$NEW_HOME" AUTOACTIVATOR_TARBALL_URL="file://$TARBALL" \
      PATH="$STUB_BIN" "$BASH" "$SETUP" bash 2>&1); rv=$?
assert_eq "tarball install exits 0" "$rv" "0"
assert_contains "tarball mode announced" "$out" "tarball"
assert_file "tarball install lays down the config" "$NEW_HOME/.autoactivator/autoactivator_config.sh"
assert_no_file "tarball install has no .git" "$NEW_HOME/.autoactivator/.git"
assert_contains "rc gained the activator block (tarball)" "$(cat "$NEW_HOME/.bashrc")" "$AUTOACTIVATOR_BLOCK_OPEN"
leftovers=$(find "$NEW_HOME" -maxdepth 1 -name '.autoactivator.new.*' | wc -l)
assert_eq "tarball staging dir cleaned up" "${leftovers//[[:space:]]/}" "0"

# 7. Tarball re-run refreshes in place, still exactly one block
out=$(HOME="$NEW_HOME" AUTOACTIVATOR_TARBALL_URL="file://$TARBALL" \
      PATH="$STUB_BIN" "$BASH" "$SETUP" bash 2>&1); rv=$?
assert_eq "tarball refresh exits 0" "$rv" "0"
assert_contains "tarball refresh announced" "$out" "Refreshing"
cnt=$(grep -cF "$AUTOACTIVATOR_BLOCK_OPEN" "$NEW_HOME/.bashrc")
assert_eq "tarball refresh keeps exactly one block" "$cnt" "1"

# 8. Re-run with git back in PATH upgrades the tarball install to a checkout
out=$(run_setup "$NEW_HOME" bash); rv=$?
assert_eq "upgrade run exits 0" "$rv" "0"
assert_contains "tarball→git upgrade announced" "$out" "Upgrading"
assert_file "upgrade produced a git checkout" "$NEW_HOME/.autoactivator/.git"

# 9. Unsupported shell argument fails
new_home home-badshell
out=$(run_setup "$NEW_HOME" fish); rv=$?
if [[ "$rv" -ne 0 ]]; then
  _pass "unsupported shell exits non-zero"
else
  _fail "unsupported shell exits non-zero" "got exit 0"
fi
assert_contains "unsupported shell names the offender" "$out" "Unsupported shell 'fish'"

# 10. No git and no curl/wget: fails with actionable guidance
new_home home-notools
out=$(HOME="$NEW_HOME" PATH="$STUB_BIN_NODL" "$BASH" "$SETUP" bash 2>&1); rv=$?
if [[ "$rv" -ne 0 ]]; then
  _pass "missing download tools exits non-zero"
else
  _fail "missing download tools exits non-zero" "got exit 0"
fi
assert_contains "missing download tools names the fix" "$out" "Install git"

# --- Summary ------------------------------------------------------------------

echo
echo "setup.sh: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
  echo "Failures:"
  for line in "${FAIL_LINES[@]}"; do
    echo "  - $line"
  done
  exit 1
fi
exit 0
