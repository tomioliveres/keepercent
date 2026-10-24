#!/bin/bash
# The single quality gate: Domain tests, then the app build and its UI tests
# on one simulator. Prints a short summary; full logs stay in the run directory.
#
# Usage: Tools/Overnight/check.sh <simulator-udid> <run-dir> [--domain-only]
set -uo pipefail

udid="${1:?simulator UDID required}"
run_dir="${2:?run directory required}"
mode="${3:-}"
root="$(git rev-parse --show-toplevel)"
mkdir -p "$run_dir"
stamp="$(date +%H%M%S)"
status=0

domain_log="$run_dir/domain-$stamp.log"
if swift test --package-path "$root/Domain" >"$domain_log" 2>&1; then
    echo "domain: pass ($(grep -Eo 'Test run with [0-9]+ tests' "$domain_log" | tail -1))"
else
    echo "domain: FAIL — see $domain_log"
    grep -E '✘|error:' "$domain_log" | head -20
    status=1
fi

[[ "$mode" == "--domain-only" ]] && exit "$status"

app_log="$run_dir/app-tests-$stamp.log"
result="$run_dir/app-tests-$stamp.xcresult"
if xcodebuild -project "$root/Keepercent.xcodeproj" -scheme Keepercent \
    -destination "id=$udid" -derivedDataPath "$root/build/DerivedData" \
    -resultBundlePath "$result" test >"$app_log" 2>&1; then
    echo "app build + UI tests: pass"
else
    echo "app build + UI tests: FAIL — see $app_log and $result"
    grep -E 'error:|Test Case .* failed|\*\* (BUILD|TEST) FAILED' "$app_log" | head -30
    status=1
fi
grep -E 'Executed [0-9]+ tests?' "$app_log" | tail -1

exit "$status"
