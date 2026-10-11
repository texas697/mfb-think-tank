#!/usr/bin/env bash
# Connect this app to a Firebase project (Android + iOS) and wire up the
# client ids that Google Sign-In needs.
#
#  1. Runs `flutterfire configure` for android+ios with the ids read from the
#     project (registers the apps if needed, writes lib/firebase_options.dart and
#     android/app/google-services.json).
#  2. Registers local SHA-1/SHA-256 fingerprints (debug keystore + upload
#     keystore from android/key.properties) on the Firebase Android app.
#  3. Downloads fresh android/app/google-services.json and
#     ios/Runner/GoogleService-Info.plist via the Firebase CLI (flutterfire only
#     writes the iOS file when run on macOS).
#  4. Patches ios/Runner/Info.plist (GIDClientID + reversed client id URL scheme)
#     and config/app_config.json (GOOGLE_IOS_CLIENT_ID, GOOGLE_SERVER_CLIENT_ID).
#
# Safe to re-run: do so after enabling the Google provider or adding SHA keys so
# the OAuth client ids get picked up.
set -euo pipefail

# shellcheck source=scripts/_common.sh
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] <firebase-project-id>

Options:
  --account <email>   Google account to use (if several are logged in to the Firebase CLI).
  --no-sha            Do not register local SHA fingerprints on the Firebase Android app.
  -h, --help          Show this help.

Prerequisites: firebase CLI (npm i -g firebase-tools; firebase login),
flutterfire CLI (dart pub global activate flutterfire_cli), python3.
EOF
}

account=''
register_sha=1
project_id=''
while (($#)); do
  case $1 in
    -h | --help) usage; exit 0 ;;
    --account) account=${2:?--account needs a value}; shift ;;
    --account=*) account=${1#*=} ;;
    --no-sha) register_sha=0 ;;
    -*) usage >&2; die "unknown option: $1" ;;
    *) [[ -z $project_id ]] || die "unexpected argument: $1"; project_id=$1 ;;
  esac
  shift
done
[[ -n $project_id ]] || { usage >&2; exit 64; }

root=$(project_root)
cd "$root"

# --- preflight -------------------------------------------------------------------
require_cmd python3
require_cmd firebase "Install with: npm install -g firebase-tools"
require_cmd flutterfire "Install with: dart pub global activate flutterfire_cli (and add ~/.pub-cache/bin to PATH)"
require_cmd flutter "Add the Flutter SDK bin directory to PATH."

if firebase login:list 2>/dev/null | grep -qi 'no authorized accounts'; then
  die "the Firebase CLI is not logged in. Run: firebase login"
fi

android_id=$(read_android_app_id "$root")
ios_id=$(read_ios_bundle_id "$root")
[[ -n $android_id ]] || die "could not read applicationId from android/app/build.gradle(.kts)."
[[ -n $ios_id ]] || die "could not read PRODUCT_BUNDLE_IDENTIFIER from ios/Runner.xcodeproj/project.pbxproj."
case "$android_id $ios_id" in
  *com[.]example[.]*) warn "ids still use the template's example org - create apps with scripts/new_app.sh (in flutter-firebase-template) before configuring Firebase." ;;
esac

fb_args=(--project "$project_id")
[[ -z $account ]] || fb_args+=(--account "$account")

info "Firebase project  $project_id"
printf '    Android package   %s\n    iOS bundle id     %s\n' "$android_id" "$ios_id"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- 1. flutterfire configure ------------------------------------------------------
info "flutterfire configure"
ff_args=(configure
  "--project=$project_id"
  '--platforms=android,ios'
  "--android-package-name=$android_id"
  "--ios-bundle-id=$ios_id"
  --out=lib/firebase_options.dart
  --yes)
[[ -z $account ]] || ff_args+=("--account=$account")
flutterfire "${ff_args[@]}"
ok "lib/firebase_options.dart generated"

# Look up the Firebase app id for a platform + identifier from `firebase apps:list`.
firebase_app_id() { # <ANDROID|IOS> <package/bundle id>
  firebase apps:list "$1" "${fb_args[@]}" --json 2>/dev/null >"$tmp/apps.json" || true
  python3 -I - "$tmp/apps.json" "$2" <<'PY'
import json, sys
raw = open(sys.argv[1], encoding="utf-8").read()
start = raw.find("{")
apps = json.loads(raw[start:]).get("result", []) if start >= 0 else []
for app in apps:
    if sys.argv[2] in (app.get("packageName"), app.get("bundleId")):
        print(app["appId"])
        break
PY
}

android_app_id=$(firebase_app_id ANDROID "$android_id")
ios_app_id=$(firebase_app_id IOS "$ios_id")
[[ -n $android_app_id ]] || die "no Firebase Android app with package '$android_id' found in project '$project_id'."
[[ -n $ios_app_id ]] || die "no Firebase iOS app with bundle id '$ios_id' found in project '$project_id'."

# --- 2. SHA fingerprints -------------------------------------------------------------
# Prints "SHA1 <hex>" and "SHA256 <hex>" lines for a keystore.
keystore_fingerprints() { # <keystore> <alias> <password-env-var>
  command -v keytool >/dev/null 2>&1 || return 0
  keytool -list -v -keystore "$1" -alias "$2" -storepass:env "$3" 2>/dev/null |
    sed -n -E 's/^[[:space:]]*(SHA1|SHA256):[[:space:]]*([0-9A-Fa-f:]+).*/\1 \2/p'
}

if ((register_sha)); then
  fingerprints=''
  if [[ -f $HOME/.android/debug.keystore ]]; then
    export DEBUG_KS_PASS=android
    fingerprints+=$(keystore_fingerprints "$HOME/.android/debug.keystore" androiddebugkey DEBUG_KS_PASS)$'\n'
  fi
  if [[ -f android/key.properties ]]; then
    prop() { sed -n -E "s/^$1[[:space:]]*=[[:space:]]*//p" android/key.properties | head -n 1; }
    store_file=$(prop storeFile)
    [[ $store_file == /* ]] || store_file="android/app/$store_file"
    if [[ -f $store_file ]]; then
      UPLOAD_KS_PASS=$(prop storePassword)
      export UPLOAD_KS_PASS
      fingerprints+=$(keystore_fingerprints "$store_file" "$(prop keyAlias)" UPLOAD_KS_PASS)$'\n'
    fi
  fi

  if [[ -n ${fingerprints//[[:space:]]/} ]]; then
    info "Registering SHA fingerprints on the Firebase Android app"
    existing=$(firebase apps:android:sha:list "$android_app_id" "${fb_args[@]}" 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d ':' || true)
    while read -r kind sha; do
      [[ -n ${sha:-} ]] || continue
      plain=$(printf '%s' "$sha" | tr '[:upper:]' '[:lower:]' | tr -d ':')
      if [[ $existing == *"$plain"* ]]; then
        ok "$kind $sha already registered"
      elif firebase apps:android:sha:create "$android_app_id" "$plain" "${fb_args[@]}" >/dev/null 2>&1; then
        ok "$kind $sha registered"
      else
        warn "could not register $kind $sha - add it manually in the Firebase console."
      fi
    done <<<"$fingerprints"
  else
    warn "no local keystores found to fingerprint (debug keystore appears after the first Android build)."
  fi
fi

# --- 3. Download fresh service files -------------------------------------------------
info "Downloading service files"
firebase apps:sdkconfig ANDROID "$android_app_id" "${fb_args[@]}" -o "$tmp/google-services.json" >/dev/null 2>&1 ||
  die "failed to download google-services.json"
firebase apps:sdkconfig IOS "$ios_app_id" "${fb_args[@]}" -o "$tmp/GoogleService-Info.plist" >/dev/null 2>&1 ||
  die "failed to download GoogleService-Info.plist"
cp "$tmp/google-services.json" android/app/google-services.json
cp "$tmp/GoogleService-Info.plist" ios/Runner/GoogleService-Info.plist
ok "android/app/google-services.json"
ok "ios/Runner/GoogleService-Info.plist"

# --- 4. Patch Info.plist + config/app_config.json -----------------------------------
info "Wiring Google Sign-In client ids"
python3 -I - "$android_id" <<'PY'
import json, os, plistlib, re, sys

android_id = sys.argv[1]
ios_cfg = plistlib.load(open("ios/Runner/GoogleService-Info.plist", "rb"))
android_cfg = json.load(open("android/app/google-services.json", encoding="utf-8"))

ios_client_id = ios_cfg.get("CLIENT_ID", "")
reversed_client_id = ios_cfg.get("REVERSED_CLIENT_ID", "")

# Web client (client_type 3) = the "server client id" google_sign_in needs on Android.
server_client_id = ""
for client in android_cfg.get("client", []):
    info = client.get("client_info", {}).get("android_client_info", {})
    if info.get("package_name") != android_id:
        continue
    candidates = list(client.get("oauth_client", []))
    other = client.get("services", {}).get("appinvite_service", {}).get("other_platform_oauth_client", [])
    candidates += other
    for oauth in candidates:
        if oauth.get("client_type") == 3:
            server_client_id = oauth.get("client_id", "")
            break

# Info.plist: text substitution keeps the file's formatting intact and is idempotent.
info_path = "ios/Runner/Info.plist"
info_text = open(info_path, encoding="utf-8").read()
if reversed_client_id:
    info_text = info_text.replace("REVERSED_CLIENT_ID_PLACEHOLDER", reversed_client_id)
    info_text = re.sub(r"com\.googleusercontent\.apps\.[A-Za-z0-9-]+", reversed_client_id, info_text)
if ios_client_id:
    info_text = info_text.replace("GOOGLE_IOS_CLIENT_ID_PLACEHOLDER", ios_client_id)
    info_text = re.sub(r"(<key>GIDClientID</key>\s*<string>)[^<]*(</string>)",
                       lambda m: m.group(1) + ios_client_id + m.group(2), info_text)
open(info_path, "w", encoding="utf-8").write(info_text)

cfg_path = "config/app_config.json"
cfg = {}
if os.path.exists(cfg_path):
    cfg = json.load(open(cfg_path, encoding="utf-8"))
if ios_client_id:
    cfg["GOOGLE_IOS_CLIENT_ID"] = ios_client_id
if server_client_id:
    cfg["GOOGLE_SERVER_CLIENT_ID"] = server_client_id
cfg.setdefault("GOOGLE_IOS_CLIENT_ID", "")
cfg.setdefault("GOOGLE_SERVER_CLIENT_ID", "")
os.makedirs("config", exist_ok=True)
with open(cfg_path, "w", encoding="utf-8") as fh:
    json.dump(cfg, fh, indent=2)
    fh.write("\n")

def report(label, value):
    print(f"    {label:<24}{value or '(missing)'}")

report("GOOGLE_IOS_CLIENT_ID", cfg["GOOGLE_IOS_CLIENT_ID"])
report("GOOGLE_SERVER_CLIENT_ID", cfg["GOOGLE_SERVER_CLIENT_ID"])
report("iOS URL scheme", reversed_client_id)
missing = []
if not ios_client_id:
    missing.append("iOS CLIENT_ID")
if not cfg["GOOGLE_SERVER_CLIENT_ID"]:
    missing.append("web (server) client id")
if missing:
    print("MISSING:" + ", ".join(missing))
PY

if grep -q 'PLACEHOLDER' ios/Runner/Info.plist; then
  warn "ios/Runner/Info.plist still contains placeholders: enable the Google provider in the Firebase console, then re-run this script."
fi

cat <<EOF

${_c_green}${_c_bold}Firebase configured for $project_id.${_c_reset} Commit the generated files:
  lib/firebase_options.dart  android/app/google-services.json  ios/Runner/GoogleService-Info.plist
  ios/Runner/Info.plist  config/app_config.json  firebase.json
  android/app/build.gradle.kts  android/settings.gradle.kts   (Google Services Gradle plugin)
  (or simply: git add -A)

Remaining console steps (docs/FIREBASE_SETUP.md):
  1. Authentication > Sign-in method: enable Email/Password, Google and Apple.
     (Google must be enabled for the web/server client id to exist - re-run this script afterwards.)
  2. Project settings > Android app ($android_id): make sure these SHA-1 + SHA-256 are listed:
       - debug keystore      (~/.android/debug.keystore)
       - upload keystore     (scripts/create_upload_keystore.sh prints them)
       - Play App Signing key (Play Console > Test and release > App integrity)
     Then re-run this script so google-services.json picks up the new OAuth clients.
  3. Apple: enable "Sign in with Apple" on the App ID $ios_id (docs/IOS_WITHOUT_MAC.md).
EOF
