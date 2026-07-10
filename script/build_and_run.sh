#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="DrumLessonOS"
PROJECT_NAME="DrumLessonOS.xcodeproj"
SCHEME_NAME="DrumLessonOS"
CONFIGURATION="${CONFIGURATION:-Debug}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

xcodebuild -quiet \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  build

APP_PATH="$(xcodebuild -project "$PROJECT_NAME" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" -showBuildSettings 2>/dev/null | awk -F' = ' '
  / BUILT_PRODUCTS_DIR = / { dir=$2 }
  / FULL_PRODUCT_NAME = / { name=$2 }
  END { print dir "/" name }
')"

open_app() {
  /usr/bin/open -n "$APP_PATH"
}

case "$MODE" in
  run|--run)
    open_app
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"com.ericshim.DrumLessonOS\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --debug|debug)
    echo "Debug from Xcode for this app bundle so EventKit/TCC uses the expected app identity." >&2
    exit 2
    ;;
  *)
    echo "usage: $0 [run|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
