#!/bin/bash
# The project's single quality gate, shared by every workflow (manual
# /next-task + /verify-ui, /auto-task, and the overnight driver). Prints a
# short summary; full logs stay in the output directory.
#
# Usage:
#   Tools/check.sh --domain-only               Domain tests
#   Tools/check.sh --build-only                Domain tests, app build, UI-test compilation (no simulator)
#   Tools/check.sh --simulator <udid>          Domain tests, then app build and every UI test on that simulator
# Options: --out <dir> (default: build/check/<timestamp>)
set -uo pipefail

mode=""
udid=""
root="$(git rev-parse --show-toplevel)"
out="$root/build/check/$(date +%Y%m%d-%H%M%S)"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain-only) mode=domain; shift ;;
        --build-only) mode=build; shift ;;
        --simulator) mode=full; udid="$2"; shift 2 ;;
        --out) out="$2"; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done
[[ -n "$mode" ]] || { echo "choose --domain-only, --build-only or --simulator <udid>" >&2; exit 2; }
mkdir -p "$out"
status=0

domain_log="$out/domain.log"
if swift test --package-path "$root/Domain" >"$domain_log" 2>&1; then
    echo "domain: pass ($(grep -Eo 'Test run with [0-9]+ tests' "$domain_log" | tail -1))"
else
    echo "domain: FAIL — see $domain_log"
    grep -E '✘|error:' "$domain_log" | head -20
    status=1
fi
[[ "$mode" == domain ]] && exit "$status"

app_log="$out/app.log"
if [[ "$mode" == build ]]; then
    destination='generic/platform=iOS Simulator'
    action=build-for-testing
    result_args=()
else
    destination="id=$udid"
    action=test
    result_args=(-resultBundlePath "$out/app.xcresult")
fi
if xcodebuild -project "$root/Keepercent.xcodeproj" -scheme Keepercent \
    -destination "$destination" -derivedDataPath "$root/build/DerivedData" \
    ${result_args[@]+"${result_args[@]}"} "$action" >"$app_log" 2>&1; then
    echo "app $action: pass"
else
    echo "app $action: FAIL — see $app_log"
    grep -E 'error:|Test Case .* failed|\*\* (BUILD|TEST)[A-Z ]* FAILED' "$app_log" | head -30
    status=1
fi
grep -E 'Executed [0-9]+ tests?' "$app_log" | tail -1

exit "$status"
