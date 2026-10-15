#!/usr/bin/env bash
# Print the rclone credentials for the Codemagic `gdrive` variable group.
#
# The release workflows archive APKs to your personal Google Drive using rclone
# with an OAuth token. A Google *service account* will not work here: it has its
# own drive with no storage quota and cannot write into a personal My Drive
# folder, and impersonation needs a Workspace domain.
#
# Usage:
#   scripts/export_gdrive_secret.sh [remote]     # default remote: gdrive-backup
#
# Paste the output into Codemagic > App > Environment variables > group `gdrive`
# (each value marked secret). Re-run this if you ever re-authorise rclone.

set -euo pipefail
source "$(dirname "$0")/_common.sh"

remote=${1:-gdrive-backup}

require_cmd rclone "install it from https://rclone.org/install/"
rclone listremotes | grep -qx "$remote:" ||
  die "no rclone remote '$remote' (see: rclone listremotes)"

cfg=$(rclone config show "$remote:")
token=$(printf '%s\n' "$cfg" | sed -n 's/^token = //p')
client_id=$(printf '%s\n' "$cfg" | sed -n 's/^client_id = //p')
client_secret=$(printf '%s\n' "$cfg" | sed -n 's/^client_secret = //p')

[ -n "$token" ] || die "remote '$remote' has no OAuth token"

info "Add these to the Codemagic 'gdrive' variable group (all secret):"
echo
printf 'GDRIVE_TOKEN=%s\n' "$token"
if [ -n "$client_id" ]; then
  printf 'GDRIVE_CLIENT_ID=%s\n' "$client_id"
  printf 'GDRIVE_CLIENT_SECRET=%s\n' "$client_secret"
else
  warn "no client_id on '$remote': it uses rclone's shared client, which is"
  warn "being retired during 2026. Create your own at"
  warn "https://rclone.org/drive/#making-your-own-client-id and reconnect rclone."
fi
