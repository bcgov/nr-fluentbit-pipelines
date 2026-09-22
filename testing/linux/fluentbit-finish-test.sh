#!/bin/sh
#
# Tests for files/fluentbit-finish.
#
# Run on Linux (it reads /proc), as an ordinary user, no agent required:
#
#   testing/linux/fluentbit-finish-test.sh
#
# or from a checkout on a non-Linux machine, in any Debian-based image:
#
#   docker run --rm -v "$PWD:/repo:ro" --entrypoint sh <image> \
#     -c 'cp -r /repo /tmp/repo && /tmp/repo/testing/linux/fluentbit-finish-test.sh'
#
# The real fluent-bit is a binary, so /proc/<pid>/exe points at the agent's own
# copy of it. The fakes here are copies of real binaries for the same reason: a
# shell script would show the interpreter instead.

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FINISH=${1:-"${SCRIPT_DIR}/../../files/fluentbit-finish"}
[ -x "$FINISH" ] || { echo "not executable: $FINISH"; exit 1; }
[ -d /proc ] || { echo "these tests need Linux (/proc)"; exit 1; }

BASE=$(mktemp -d)
trap 'rm -rf "$BASE"' EXIT

fail=0
check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "PASS: $1"; else echo "FAIL: $1 (expected '$2', got '$3')"; fail=1; fi
}
alive() { kill -0 "$1" 2>/dev/null && echo yes || echo no; }

for n in 0 1; do
  mkdir -p "${BASE}/agents/fluent-bit.${n}/bin" "${BASE}/s6/fluent-bit.${n}"
  cp /bin/sleep "${BASE}/agents/fluent-bit.${n}/bin/fluent-bit"
  cp "$FINISH" "${BASE}/agents/fluent-bit.${n}/bin/fluentbit-finish"
  : > "${BASE}/agents/fluent-bit.${n}/bin/fluentbitw"
  chmod 755 "${BASE}/agents/fluent-bit.${n}/bin/"*
  ln -sfn "${BASE}/agents/fluent-bit.${n}/bin/fluentbitw" "${BASE}/s6/fluent-bit.${n}/run"
  ln -sfn "${BASE}/agents/fluent-bit.${n}/bin/fluentbit-finish" "${BASE}/s6/fluent-bit.${n}/finish"
done

echo "== 1. stops this agent's leftover fluent-bit, leaves other agents alone"
"${BASE}/agents/fluent-bit.0/bin/fluent-bit" 300 & a0=$!
"${BASE}/agents/fluent-bit.1/bin/fluent-bit" 300 & a1=$!
sleep 1
( cd "${BASE}/s6/fluent-bit.0" && ./finish )
sleep 1
check "agent 0 leftover stopped" no "$(alive $a0)"
check "agent 1 untouched" yes "$(alive $a1)"

echo "== 2. nothing left over: silent no-op"
out=$( cd "${BASE}/s6/fluent-bit.0" && ./finish ); rc=$?
check "exit code" 0 "$rc"
check "no output" "" "$out"

echo "== 3. argument form, used by fluentbitw before it starts an agent"
"${BASE}/agents/fluent-bit.1/bin/fluentbit-finish" "${BASE}/agents/fluent-bit.1/bin" >/dev/null
sleep 1
check "agent 1 stopped via argument" no "$(alive $a1)"

echo "== 4. binary replaced by a later deployment, shown as (deleted) in /proc"
"${BASE}/agents/fluent-bit.0/bin/fluent-bit" 300 & a0=$!
sleep 1
rm "${BASE}/agents/fluent-bit.0/bin/fluent-bit"
cp /bin/sleep "${BASE}/agents/fluent-bit.0/bin/fluent-bit"
( cd "${BASE}/s6/fluent-bit.0" && ./finish ) >/dev/null
sleep 1
check "leftover on a replaced binary stopped" no "$(alive $a0)"

echo "== 5. a process ignoring SIGTERM gets SIGKILL, inside s6's 5s timeout-finish"
if command -v perl >/dev/null; then
  cp "$(command -v perl)" "${BASE}/agents/fluent-bit.0/bin/fluent-bit"
  "${BASE}/agents/fluent-bit.0/bin/fluent-bit" -e '$SIG{TERM}="IGNORE"; sleep 300' & a0=$!
  sleep 1
  start=$(date +%s)
  ( cd "${BASE}/s6/fluent-bit.0" && ./finish ) >/dev/null
  elapsed=$(( $(date +%s) - start ))
  check "stubborn leftover stopped" no "$(alive $a0)"
  if [ "$elapsed" -lt 5 ]; then
    echo "PASS: finished in ${elapsed}s (s6 kills finish at 5s)"
  else
    echo "FAIL: took ${elapsed}s, s6 kills finish at 5s"; fail=1
  fi
else
  echo "SKIP: no perl to build a SIGTERM-ignoring process"
fi

echo "== 6. no run symlink and no argument: no-op"
mkdir -p "${BASE}/s6/empty"
out=$( cd "${BASE}/s6/empty" && "${BASE}/agents/fluent-bit.0/bin/fluentbit-finish" ); rc=$?
check "exit code" 0 "$rc"
check "no output" "" "$out"

if [ "$fail" -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "SOME TESTS FAILED"; fi
exit "$fail"
