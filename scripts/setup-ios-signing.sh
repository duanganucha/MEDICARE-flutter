#!/usr/bin/env bash
# Recreate and install the App Store provisioning profile through the
# App Store Connect API. Use when Xcode cannot reach Apple to do it itself.
set -euo pipefail
python3 - <<'PYEOF'
import jwt, time, os, base64, requests

KEY_ID = "6ZFTG727H4"
ISSUER = "69a6de87-937a-47e3-e053-5b8c7c11a4d1"
BUNDLE = "th.go.sskhospital.medicare"
key = open(f"{os.environ['HOME']}/.appstoreconnect/private_keys/"
           f"AuthKey_{KEY_ID}.p8").read()
tok = jwt.encode({"iss": ISSUER, "exp": int(time.time()) + 1200,
                  "aud": "appstoreconnect-v1"},
                 key, algorithm="ES256", headers={"kid": KEY_ID})
H = {"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}
A = "https://api.appstoreconnect.apple.com/v1"

bid = requests.get(f"{A}/bundleIds", headers=H,
                   params={"filter[identifier]": BUNDLE}, timeout=25
                   ).json()["data"][0]["id"]
cert = requests.get(f"{A}/certificates", headers=H,
                    params={"filter[certificateType]": "DISTRIBUTION"},
                    timeout=25).json()["data"][0]["id"]

r = requests.post(f"{A}/profiles", headers=H, json={"data": {
    "type": "profiles",
    "attributes": {"name": "MEDICARE AppStore",
                   "profileType": "IOS_APP_STORE"},
    "relationships": {
        "bundleId": {"data": {"type": "bundleIds", "id": bid}},
        "certificates": {"data": [{"type": "certificates", "id": cert}]}}}},
    timeout=30)
if r.status_code not in (200, 201):
    raise SystemExit(r.text[:400])

p = r.json()["data"]["attributes"]
dest = os.path.expanduser("~/Library/Developer/Xcode/UserData/"
                          f"Provisioning Profiles/{p['uuid']}.mobileprovision")
os.makedirs(os.path.dirname(dest), exist_ok=True)
open(dest, "wb").write(base64.b64decode(p["profileContent"]))
print("installed:", dest)
PYEOF
