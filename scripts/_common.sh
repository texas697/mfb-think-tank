# shellcheck shell=bash
# Shared helpers for the scripts in this directory. Source it; do not execute.
# Works with bash 3.2 (macOS default) and GNU/BSD userlands.

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  _c_red=$'\033[31m' _c_yellow=$'\033[33m' _c_green=$'\033[32m' _c_bold=$'\033[1m' _c_reset=$'\033[0m'
else
  _c_red='' _c_yellow='' _c_green='' _c_bold='' _c_reset=''
fi

info() { printf '%s==>%s %s\n' "$_c_bold" "$_c_reset" "$*"; }
ok() { printf '%s✓%s %s\n' "$_c_green" "$_c_reset" "$*"; }
warn() { printf '%swarning:%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2; }
die() {
  printf '%serror:%s %s\n' "$_c_red" "$_c_reset" "$*" >&2
  exit 1
}

require_cmd() {
  local cmd=$1 hint=${2:-}
  command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' not found on PATH.${hint:+ $hint}"
}

# Absolute path of the project root (parent of scripts/).
project_root() {
  (cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
}

# In-place sed that works with both GNU sed (Linux) and BSD sed (macOS).
# Usage: sed_inplace 's/a/b/g' file...
sed_inplace() {
  local expr=$1 f
  shift
  for f in "$@"; do
    sed -e "$expr" "$f" >"$f.__tmp__" && cat "$f.__tmp__" >"$f" && rm -f "$f.__tmp__"
  done
}

# Escape a literal string for use on the left-hand side of a sed s||| (BRE).
sed_escape_pattern() { printf '%s' "$1" | sed -e 's/[]\/$*.^[|]/\\&/g'; }

# Escape a literal string for use on the right-hand side of a sed s|||.
sed_escape_replacement() { printf '%s' "$1" | sed -e 's/[\/&|]/\\&/g'; }

# Android applicationId from android/app/build.gradle(.kts).
read_android_app_id() {
  local root=$1 f
  for f in "$root/android/app/build.gradle.kts" "$root/android/app/build.gradle"; do
    [[ -f $f ]] || continue
    sed -n -E 's/^[[:space:]]*applicationId[[:space:]]*=?[[:space:]]*"([^"]+)".*/\1/p' "$f" | head -n 1
    return 0
  done
}

# iOS bundle id of the Runner target (first PRODUCT_BUNDLE_IDENTIFIER that is not a test target).
read_ios_bundle_id() {
  local root=$1
  sed -n -E 's/^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER = "?([^";]+)"?;.*/\1/p' \
    "$root/ios/Runner.xcodeproj/project.pbxproj" | grep -v 'RunnerTests$' | head -n 1
}

# Dart package name from pubspec.yaml.
read_pubspec_name() {
  sed -n -E 's/^name:[[:space:]]*([a-z0-9_]+).*/\1/p' "$1/pubspec.yaml" | head -n 1
}
