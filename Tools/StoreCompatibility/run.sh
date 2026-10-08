#!/bin/bash
set -euo pipefail
# Disposable stores and build products only; never use the app's real store.
# Retain evidence on success and failure rather than removing filesystem state.
root="$(git rev-parse --show-toplevel)"
directory="$(mktemp -d /var/folders/4k/20l7cw4s07z28vbtfqtvb34m0000gn/T/opencode/keepercent-compatibility.XXXXXX)"
export KEEPERCENT_COMPATIBILITY_DIRECTORY="$directory"
printf 'Compatibility evidence directory: %s\n' "$directory"
swift run --package-path "$root" --scratch-path "$directory/build" LegacyStore "$directory"
swift run --package-path "$root" --scratch-path "$directory/build" MC4Store "$directory"
swift test --package-path "$root" --scratch-path "$directory/build" --filter 'StoreCompatibilityTests|OwnAttributionStoreTests'
