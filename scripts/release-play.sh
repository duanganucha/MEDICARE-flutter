#!/usr/bin/env bash
# Build the AAB and release it to a Play track.
#
#   ./scripts/release-play.sh                 # internal track
#   ./scripts/release-play.sh internal "note" # with release notes
#   ./scripts/release-play.sh production "note"
#   STATUS=completed ./scripts/release-play.sh production "note"
#
# STATUS defaults to "draft": the build is staged and you press
# "Send for review" in the console. Use STATUS=completed to roll out
# straight away, which only works once the app is no longer a draft.
#
# Uploading through the API avoids the browser's file-size limit.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACK="${1:-internal}"
NOTES="${2:-ปรับปรุงและแก้ไขข้อผิดพลาด}"
# Play rejects a "completed" release while the app is still a draft
# ("Only releases with status draft may be created on draft app"), so stage
# as draft unless STATUS says otherwise.
STATUS="${STATUS:-draft}"
AAB="$ROOT/build/app/outputs/bundle/release/app-release.aab"
KEY="${PLAY_SA_KEY:-$HOME/Documents/PrivateKeyStore/hin-korat/hin-korat-0296ccd3d4b8.json}"
VENV="$ROOT/.venv-play"

cd "$ROOT"
echo "=== 1/2 Build AAB ==="
flutter build appbundle --release
[[ -f "$AAB" ]] || { echo "ERROR: $AAB not found" >&2; exit 1; }
echo "AAB: $(du -sh "$AAB" | cut -f1)"

if [[ ! -d "$VENV" ]]; then
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --quiet --upgrade pip
  "$VENV/bin/pip" install --quiet google-api-python-client google-auth
fi

echo ""
echo "=== 2/2 Upload to Play ($TRACK) ==="
"$VENV/bin/python" - "$AAB" "$KEY" "$TRACK" "$NOTES" "$STATUS" <<'PYEOF'
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

aab, key, track, notes, status = sys.argv[1:6]
PKG = "th.go.sskhospital.medicare"

creds = service_account.Credentials.from_service_account_file(
    key, scopes=["https://www.googleapis.com/auth/androidpublisher"])
svc = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)
edits = svc.edits()

edit_id = edits.insert(packageName=PKG, body={}).execute()["id"]
media = MediaFileUpload(aab, mimetype="application/octet-stream",
                        resumable=True, chunksize=5 * 1024 * 1024)
vc = edits.bundles().upload(
    packageName=PKG, editId=edit_id, media_body=media).execute()["versionCode"]
print("versionCode:", vc)

edits.tracks().update(
    packageName=PKG, editId=edit_id, track=track,
    body={"releases": [{
        "name": f"v{vc}", "versionCodes": [str(vc)], "status": status,
        "releaseNotes": [{"language": "th-TH", "text": notes}]}]}).execute()

edits.commit(packageName=PKG, editId=edit_id).execute()
print(f"released to {track} (status={status})")
PYEOF
echo "Done."
