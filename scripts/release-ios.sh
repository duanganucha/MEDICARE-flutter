#!/usr/bin/env bash
# Build, sign and upload the iOS app to TestFlight.
#
#   ./scripts/release-ios.sh            # uses the build number in pubspec.yaml
#   ./scripts/release-ios.sh 2          # override the build number
#
# Requires APP_ID, which only exists once the app record has been created
# at appstoreconnect.apple.com (the API forbids creating app records).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_ID="6ZFTG727H4"
ISSUER_ID="69a6de87-937a-47e3-e053-5b8c7c11a4d1"
APP_ID="${MEDICARE_APP_ID:-6824204699}"   # App Store Connect app id
IPA="$ROOT/build/ios/ipa/MEDICARE.ipa"

BUILD_NUMBER="${1:-$(grep '^version:' "$ROOT/pubspec.yaml" | grep -o '+.*' | tr -d '+')}"

echo "=== 1/3 Build and export IPA (build $BUILD_NUMBER) ==="
cd "$ROOT"
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist \
  || {
    # Xcode cannot always reach Apple; fall back to exporting the archive
    # that the failed run already produced, using the manual-signing plist.
    echo "flutter export failed, retrying with xcodebuild..."
    xcodebuild -exportArchive \
      -archivePath build/ios/archive/Runner.xcarchive \
      -exportOptionsPlist ios/ExportOptions.plist \
      -exportPath build/ios/ipa
  }
[[ -f "$IPA" ]] || { echo "ERROR: $IPA not found" >&2; exit 1; }
echo "IPA: $(du -sh "$IPA" | cut -f1)"

echo ""
echo "=== 2/3 Upload ==="
if [[ -z "$APP_ID" ]]; then
  echo "MEDICARE_APP_ID is not set — opening Transporter instead."
  echo "Create the app at appstoreconnect.apple.com, then:"
  echo "  export MEDICARE_APP_ID=<numeric id>"
  open -a Transporter "$IPA"
  exit 0
fi
xcrun altool --upload-app -f "$IPA" -t ios \
  --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"

echo ""
echo "=== 3/3 Submit to TestFlight ==="
python3 - "$BUILD_NUMBER" "$APP_ID" <<'PYEOF'
import jwt, time, os, sys, requests

build_number, app_id = sys.argv[1], sys.argv[2]
KEY_ID = "6ZFTG727H4"
ISSUER = "69a6de87-937a-47e3-e053-5b8c7c11a4d1"
key = open(f"{os.environ['HOME']}/.appstoreconnect/private_keys/"
           f"AuthKey_{KEY_ID}.p8").read()

tok = jwt.encode({"iss": ISSUER, "exp": int(time.time()) + 1200,
                  "aud": "appstoreconnect-v1"},
                 key, algorithm="ES256", headers={"kid": KEY_ID})
H = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}
A = "https://api.appstoreconnect.apple.com/v1"

# Processing takes a few minutes, so poll rather than fail immediately.
for attempt in range(20):
    r = requests.get(f"{A}/builds", headers=H, params={
        "filter[app]": app_id, "filter[version]": build_number,
        "sort": "-uploadedDate", "limit": 1}, timeout=30)
    builds = r.json().get("data", [])
    if builds:
        break
    print(f"  waiting for build to process ({attempt + 1}/20)...")
    time.sleep(30)
else:
    sys.exit(f"No build {build_number} appeared for app {app_id}")

bid = builds[0]["id"]
requests.patch(f"{A}/builds/{bid}", headers=H, json={"data": {
    "type": "builds", "id": bid,
    "attributes": {"usesNonExemptEncryption": False}}}, timeout=30)

r = requests.post(f"{A}/betaAppReviewSubmissions", headers=H, json={"data": {
    "type": "betaAppReviewSubmissions",
    "relationships": {"build": {"data": {"type": "builds", "id": bid}}}}},
    timeout=30)
if r.status_code in (200, 201):
    print("TestFlight:", r.json()["data"]["attributes"]["betaReviewState"])
else:
    sys.exit(f"ERROR {r.status_code}: {r.text[:300]}")
PYEOF
echo "Done."
