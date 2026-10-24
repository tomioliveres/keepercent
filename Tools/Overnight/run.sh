#!/bin/bash
# Unattended driver: runs /auto-task for each queued `auto` task on the
# integration branch overnight/<date>, in its own worktree and simulator.
# A finished task is fast-forwarded into the integration branch and pushed;
# a blocked or failed one keeps its commits on auto/<task> and is skipped.
# `main` is never touched. See docs/overnight.md.
#
# Usage: Tools/Overnight/run.sh [--max-tasks N] [--base REF] [--dry-run]
set -euo pipefail

max_tasks=6
base=main
dry_run=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max-tasks) max_tasks="$2"; shift 2 ;;
        --base) base="$2"; shift 2 ;;
        --dry-run) dry_run=1; shift ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
main_root="$(dirname "$common_dir")"
script_root="$(git rev-parse --show-toplevel)"
worktree="$(dirname "$main_root")/keepercent-overnight"
date="$(date +%Y-%m-%d)"
integration="overnight/$date"
stop_file="$common_dir/overnight-STOP"
simulator_name="Keepercent Overnight"
publish_account=tomioliveres
default_account=atomdev1

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

# Prints "<task> <model>" for every open auto task, in file order.
queued_tasks() {
    awk '/^- \[ \] [^ ]+ · auto · [^ ]+/ { print $4, $8 }' "$1"
}

preflight() {
    local problems=0
    for tool in claude xcodebuild xcrun swift gh; do
        command -v "$tool" >/dev/null || { log "missing tool: $tool"; problems=1; }
    done
    command -v codex >/dev/null || log "warning: codex missing; reviews will be recorded as unavailable"
    if (cd "$main_root" && gentle-ai review mode status 2>/dev/null | grep -q 'development: on'); then
        log "receipt-driven review is on; run: gentle-ai review mode disable --scope clone --cwd $main_root"
        problems=1
    fi
    [[ -f "$stop_file" ]] && { log "stop file present: $stop_file"; problems=1; }
    git -C "$main_root" rev-parse --verify --quiet "$base^{commit}" >/dev/null || { log "unknown base: $base"; problems=1; }
    return "$problems"
}

if [[ "$dry_run" == 1 ]]; then
    preflight || log "preflight would stop a real run"
    log "base: $base · integration: $integration · worktree: $worktree · max tasks: $max_tasks"
    log "queue in $script_root/odd/overnight/queue.md:"
    queued_tasks "$script_root/odd/overnight/queue.md" | sed 's/^/    /'
    exit 0
fi

preflight || exit 1

# Integration worktree.
if [[ ! -d "$worktree" ]]; then
    if git -C "$main_root" rev-parse --verify --quiet "refs/heads/$integration" >/dev/null; then
        git -C "$main_root" worktree add "$worktree" "$integration"
    else
        git -C "$main_root" worktree add -b "$integration" "$worktree" "$base"
    fi
fi
if [[ -n "$(git -C "$worktree" status --porcelain)" ]]; then
    log "integration worktree is not clean: $worktree"; exit 1
fi
git -C "$worktree" rev-parse --verify --quiet "refs/heads/$integration" >/dev/null \
    || git -C "$worktree" branch "$integration" "$base"
git -C "$worktree" switch --quiet "$integration"

# Dedicated simulator, so interactive sessions keep theirs.
udid="$(xcrun simctl list devices available | grep "$simulator_name (" | grep -Eo '[0-9A-F-]{36}' | head -1 || true)"
if [[ -z "$udid" ]]; then
    udid="$(xcrun simctl create "$simulator_name" "iPhone 17")"
    log "created simulator $simulator_name ($udid)"
fi
xcrun simctl bootstatus "$udid" -b >/dev/null

night_dir="$worktree/build/overnight/$date"
mkdir -p "$night_dir"
summary="$night_dir/summary.md"
[[ -f "$summary" ]] || printf '# Overnight run %s\n\nIntegration branch: `%s` (base `%s`)\n\n' "$date" "$integration" "$base" >"$summary"

caffeinate -dimsu -w $$ &
trap 'gh auth switch -h github.com -u "$default_account" >/dev/null 2>&1 || true' EXIT

push_integration() {
    local rc=0
    gh auth switch -h github.com -u "$publish_account" >/dev/null || return 1
    git -C "$worktree" push --quiet -u origin "$integration" || rc=$?
    gh auth switch -h github.com -u "$default_account" >/dev/null || true
    return "$rc"
}

instructions="Unattended overnight run of the Keepercent project. Follow the /auto-task skill strictly. Never ask questions or wait for input: record anything that needs the author and finish as blocked. The project CLAUDE.md lightweight process profile applies: no receipt-driven review commands, no ODD feature documents, no Engram mirrors of task files. Reply in Spanish."

skipped=()
ran=0
consecutive_failures=0
while (( ran < max_tasks )); do
    [[ -f "$stop_file" ]] && { log "stop file found; stopping"; break; }

    task="" model=""
    while read -r candidate candidate_model; do
        [[ " ${skipped[*]-} " == *" $candidate "* ]] && continue
        task="$candidate" model="$candidate_model"; break
    done < <(queued_tasks "$worktree/odd/overnight/queue.md")
    [[ -z "$task" ]] && { log "queue empty"; break; }

    ran=$((ran + 1))
    run_dir="$night_dir/$task"
    mkdir -p "$run_dir"
    rm -f "$run_dir/result"
    log "task $task with $model"
    started="$(date +%s)"

    (cd "$worktree" && KP_TASK="$task" KP_BASE="$integration" KP_RUN_DIR="$run_dir" KP_SIMULATOR="$udid" \
        claude -p "/auto-task $task" --model "$model" --permission-mode auto \
            --settings "$worktree/Tools/Overnight/settings.json" \
            --append-system-prompt "$instructions" \
            --output-format json --no-session-persistence \
            >"$run_dir/claude.json" 2>"$run_dir/claude.err") || log "claude exited with $?"

    status="$(sed -n 1p "$run_dir/result" 2>/dev/null || true)"
    reason="$(sed -n 2p "$run_dir/result" 2>/dev/null || true)"
    branch="$(git -C "$worktree" branch --show-current)"
    minutes=$(( ($(date +%s) - started) / 60 ))

    if [[ -n "$(git -C "$worktree" status --porcelain)" ]]; then
        git -C "$worktree" add -A
        git -C "$worktree" commit --quiet -m "wip($task): unfinished overnight attempt"
        [[ "$status" == done ]] && status=failed reason="left uncommitted changes"
    fi

    if [[ "$status" == done && "$branch" != "$integration" ]] \
        && git -C "$worktree" merge-base --is-ancestor "$integration" "$branch"; then
        git -C "$worktree" switch --quiet "$integration"
        git -C "$worktree" merge --quiet --ff-only "$branch"
        if push_integration; then pushed=pushed; else pushed="push failed"; fi
        consecutive_failures=0
        log "$task done in ${minutes}m ($pushed): $reason"
        printf -- '- **%s** done (%s min, %s, `%s`): %s\n' "$task" "$minutes" "$pushed" "$branch" "$reason" >>"$summary"
    else
        [[ -z "$status" ]] && status=failed reason="no result file (see claude.err; quota or crash?)"
        git -C "$worktree" switch --quiet "$integration"
        skipped+=("$task")
        consecutive_failures=$((consecutive_failures + 1))
        log "$task $status in ${minutes}m: $reason"
        printf -- '- **%s** %s (%s min, work kept on `%s`): %s\n' "$task" "$status" "$minutes" "$branch" "$reason" >>"$summary"
        (( consecutive_failures >= 2 )) && { log "two failures in a row; stopping"; break; }
    fi
done

xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
log "summary: $summary"
