#!/usr/bin/env bash
# flutter run with the app's non-secret runtime config (config/app_config.json).
# Any extra arguments are passed through, e.g.:
#   scripts/run.sh -d emulator-5554
#   scripts/run.sh --release
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
exec flutter run --dart-define-from-file=config/app_config.json "$@"
