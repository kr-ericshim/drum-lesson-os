#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="DrumLessonOS"
PROJECT_NAME="DrumLessonOS.xcodeproj"
SCHEME_NAME="DrumLessonOS"
CONFIGURATION="${CONFIGURATION:-Debug}"
SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-YES}"
DATABASE_ENV="DRUM_LESSON_OS_DATABASE_PATH"
PREVIEW_CALENDAR_ENV="DRUM_LESSON_OS_PREVIEW_CALENDAR"
SAFE_RUNTIME_DIR=""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it before building Drum Lesson OS." >&2
  exit 1
fi

xcodegen generate

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

xcodebuild -quiet \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED="$SIGNING_ALLOWED" \
  build

APP_PATH="$(xcodebuild -project "$PROJECT_NAME" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" -showBuildSettings 2>/dev/null | awk -F' = ' '
  / BUILT_PRODUCTS_DIR = / { dir=$2 }
  / FULL_PRODUCT_NAME = / { name=$2 }
  END { print dir "/" name }
')"

open_app() {
  /usr/bin/open -n "$APP_PATH"
}

prepare_safe_runtime() {
  SAFE_RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/DrumLessonOS-verify.XXXXXX")"
  SAFE_DATABASE_PATH="$SAFE_RUNTIME_DIR/DrumLessonOS.sqlite"
}

open_safe_app() {
  /usr/bin/open -n \
    --env "$DATABASE_ENV=$SAFE_DATABASE_PATH" \
    --env "$PREVIEW_CALENDAR_ENV=1" \
    "$APP_PATH"
}

cleanup() {
  if [[ -n "$SAFE_RUNTIME_DIR" ]]; then
    rm -rf "$SAFE_RUNTIME_DIR"
  fi
}

trap cleanup EXIT

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
    prepare_safe_runtime
    open_safe_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    pkill -x "$APP_NAME" >/dev/null 2>&1 || true
    ;;
  --debug|debug)
    prepare_safe_runtime
    xcrun lldb \
      -o "settings set target.env-vars $DATABASE_ENV=$SAFE_DATABASE_PATH $PREVIEW_CALENDAR_ENV=1" \
      -- "$APP_PATH/Contents/MacOS/$APP_NAME"
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
