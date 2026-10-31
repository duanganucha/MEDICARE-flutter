# คำสั่งที่ต้องรันเอง

เครื่องที่ผมทำงานอยู่ **ไม่มีเน็ตออกนอก** (ทดสอบแล้ว: github.com, Apple, Play
ติดต่อไม่ได้ทั้งหมด) ทุกอย่างที่ไม่ต้องใช้เน็ตทำเสร็จหมดแล้ว
เหลือ 3 ชุดคำสั่งนี้ที่ต้องรันในเทอร์มินัลของคุณ

---

## ⚠ ก่อนอื่น: สำรอง keystore

สำเนาเก็บไว้ที่:
```
~/Documents/PrivateKeyStore/medicare/
```
(ที่เดียวกับ key ของโปรเจกต์อื่น — hin-korat, payroll)

⚠️ **ยังอยู่บนเครื่องนี้เครื่องเดียว** ควรก๊อปไปที่อื่นอีกอย่างน้อย 1 ที่
(Google Drive ส่วนตัว / USB) เพราะ **ถ้าหายจะอัปเดตแอปบน Play ไม่ได้อีกตลอดไป**
ต้องสร้างแอปใหม่ เปลี่ยน package name และผู้ใช้เดิมอัปเดตไม่ได้

ตัวที่ build ใช้อยู่ที่ `android/upload-keystore.jks` (gitignore ไว้แล้ว ไม่ขึ้น GitHub)

---

## 1. GitHub (ทำก่อน — สโตร์ต้องใช้ลิงก์นี้)

```sh
cd /Users/duanganucha/Desktop/Rx_Apps/Rx_MEDICARE_flutter

# token เดิมหมดอายุ ต้อง login ใหม่
gh auth login

# สร้าง repo แบบ public แล้ว push ในคำสั่งเดียว
gh repo create MEDICARE-flutter --public --source=. --remote=origin --push

# เปิด GitHub Pages ให้เสิร์ฟจากโฟลเดอร์ docs/
gh api -X POST repos/duanganucha/MEDICARE-flutter/pages \
  -f 'source[branch]=main' -f 'source[path]=/docs'
```

รอ 1–2 นาที แล้วเช็กว่าใช้ได้:
```sh
open https://duanganucha.github.io/MEDICARE-flutter/privacy.html
```

> ถ้า `gh api` ไม่ผ่าน ให้เปิดเว็บแทน: Settings → Pages →
> Source: Deploy from a branch → Branch `main`, Folder `/docs` → Save

---

## 2. Google Play — คุณอัปไฟล์เอง

ไฟล์ที่ต้องอัป (พร้อมแล้ว):
```
build/app/outputs/bundle/release/app-release.aab
```

เปิด https://play.google.com/console → Create app → แล้ว:

| ช่อง | ใช้ค่านี้ |
|---|---|
| App name | MEDICARE |
| ภาษาหลัก | ไทย |
| ประเภท | App (ไม่ใช่เกม) |
| ราคา | Free |

จากนั้น Production → Create new release → อัปไฟล์ `.aab` ด้านบน
**ตอบรับ Play App Signing เมื่อระบบถาม**

ข้อความและรูปทั้งหมดอยู่ใน `store/LISTING.md` และ `store/assets/`:
- ไอคอน → `store/assets/icon-512-play.png`
- Feature graphic → `store/assets/feature-1024x500.png`
- Screenshot → `store/assets/screenshots/` (5 ภาพ)
- Privacy policy → `https://duanganucha.github.io/MEDICARE-flutter/privacy.html`

---

## 3. App Store — ต้องสร้าง App ID ก่อน

ตอนนี้ยังไม่มี provisioning profile เพราะ **App ID ยังไม่ถูกสร้าง**
ทำตามนี้:

### 3.1 สร้าง App ID
https://developer.apple.com/account/resources/identifiers/list
→ **+** → App IDs → App → Continue
- Description: `MEDICARE`
- Bundle ID: **Explicit** → `th.go.sskhospital.medicare`
- Capabilities: ไม่ต้องติ๊กอะไร (แอปไม่ใช้ push, iCloud ฯลฯ)
→ Continue → Register

### 3.2 สร้างแอปใน App Store Connect
https://appstoreconnect.apple.com → My Apps → **+** → New App
- Platform: iOS
- Name: `MEDICARE`
- Primary language: Thai
- Bundle ID: เลือก `th.go.sskhospital.medicare` ที่เพิ่งสร้าง
- SKU: `medicare-2026`

### 3.3 Build แล้วส่งขึ้น TestFlight
```sh
cd /Users/duanganucha/Desktop/Rx_Apps/Rx_MEDICARE_flutter
flutter build ipa --release
```
Xcode จะสร้าง provisioning profile ให้อัตโนมัติ (ตอนนี้มีเน็ตแล้ว)

ได้ไฟล์ `build/ios/ipa/MEDICARE.ipa` → ส่งขึ้นด้วย:
```sh
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
  --apiKey 6ZFTG727H4 --apiIssuer <ISSUER_ID>
```
`<ISSUER_ID>` หาได้ที่ App Store Connect → Users and Access → Integrations
→ App Store Connect API → คอลัมน์ **Issuer ID** (เป็น UUID ยาวๆ)

หรือง่ายกว่า: เปิด **Transporter** (ฟรีจาก Mac App Store) แล้วลากไฟล์ `.ipa` เข้าไป

### 3.4 Screenshot
พร้อมแล้วที่ `store/assets/screenshots-ios/` — ขนาด 1320×2868 (6.9")
4 ภาพ ซึ่งเกินขั้นต่ำที่ Apple ต้องการ (3 ภาพ)

### 3.5 กรอกข้อมูลแล้วส่งตรวจ
- ข้อความจาก `store/LISTING.md`
- App Privacy → **Data Not Collected**
- Export compliance → **No** (ตั้ง flag ไว้ในแอปแล้ว)

---

## ถ้าจะออกเวอร์ชันใหม่

แก้ `pubspec.yaml`:
```yaml
version: 1.0.1+2     # +2 ต้องเพิ่มทุกครั้งที่อัปขึ้นสโตร์
```
```sh
flutter build appbundle --release   # Play
flutter build ipa --release         # App Store
```

---

## อัปรูปหน้าร้าน Play (ต้องทำเองในเบราว์เซอร์)

ข้อความหน้าร้านกรอกไว้ให้แล้ว (บันทึกเป็น draft) เหลือแค่รูป
เพราะปุ่ม "Add assets" เปิด native file picker ที่สคริปต์ควบคุมไม่ได้
และ API ปฏิเสธการ commit หน้าร้านของแอปที่ยังไม่เคย publish (403 ทุกครั้ง)

เปิด: Grow users → Store presence → Store listings → Default store listing

| ช่อง | ไฟล์ |
|---|---|
| App icon | `store/assets/icon-512-play.png` |
| Feature graphic | `store/assets/feature-1024x500.png` |
| Phone screenshots | `store/assets/screenshots/` ทั้ง 5 ไฟล์ |

ลากไฟล์วางในกรอบ หรือกด "Add assets" แล้วเลือกไฟล์ → Save

## Play Store — เสร็จครบแล้ว (31 ต.ค. 2026)

ทั้ง store listing และ declaration ทั้ง 10 ข้อทำเสร็จผ่าน Play Console แล้ว
หน้า App content ขึ้น "You're all caught up"

### เรื่อง API: service account แก้ store listing ไม่ได้

`scripts/play-listing.py` อัปข้อความ + รูปทั้ง 7 ภาพผ่าน API ได้สำเร็จทุกไฟล์
แต่ `edits.commit()` ตอบ 403 PERMISSION_DENIED

ทดสอบแยกแล้ว (เพื่อไม่ต้องลองซ้ำ):

| ทดสอบ | ผล |
|---|---|
| `images().upload()` ทั้ง 7 ไฟล์ | ✅ ได้ sha1 กลับมาทุกไฟล์ |
| `listings().update()` | ✅ |
| `commit()` แบบ edit **ว่าง** | ✅ |
| `commit()` ที่แก้ description | ❌ 403 |
| `commit()` ที่มีรูป | ❌ 403 |

**สรุป:** `play-uploader@hin-korat.iam.gserviceaccount.com` อัป AAB ได้
แต่ไม่มีสิทธิ์ **Manage store presence** → commit ที่แก้ listing จริงถูกปฏิเสธ
(commit ที่ไม่เปลี่ยนอะไรเลยผ่าน — อย่าเอาไปตีความว่ามีสิทธิ์)

ถ้าจะใช้ API แก้ listing ในอนาคต: Play Console → Users and permissions
→ ติ๊ก **Manage store presence** แล้วรัน `.venv-play/bin/python scripts/play-listing.py`

### หมายเหตุสำคัญ 2 ข้อ

1. **รหัสภาษาคือ `th` ไม่ใช่ `th-TH`** — ใช้ `th-TH` จะได้ 400
   "The requested language is not currently supported"

2. **อัปรูปผ่าน browser ได้** แม้ปุ่ม "Add assets" จะเปิด native file picker
   วิธี: patch `HTMLInputElement.prototype.click` ให้ไม่เปิด dialog สำหรับ
   `type=file` → กดปุ่ม → input ถูกสร้างใน DOM → ยัดไฟล์เข้า input โดยตรง
   (Play จะ deduplicate กับรูปที่เคยอัปผ่าน API ให้เอง)

### คำตอบ declaration ที่ใช้ไป

| หัวข้อ | คำตอบ |
|---|---|
| Privacy policy | https://duanganucha.github.io/MEDICARE-flutter/privacy.html |
| Ads | No |
| Sign in details | No (ไม่มี login/payment) |
| Content rating | All ages (IARC, All Other App Types) |
| Target audience | 18 and over |
| Data safety | ไม่เก็บ ไม่แชร์ข้อมูล |
| Advertising ID | No |
| Government apps | No |
| Financial features | ไม่มี |
| Health apps | Medication and treatment management |

อ้างอิงที่ตรวจจริงก่อนตอบ: dependency มีแค่ `cupertino_icons`,
ไม่มี ad/analytics SDK, และ **ไม่มี uses-permission เลยสักตัว**
ใน AndroidManifest.xml

### package ID

`th.go.sskhospital.medicare` — **เปลี่ยนไม่ได้** เพราะมี versionCode 1, 2
อัปขึ้น Play แล้ว การเปลี่ยนชื่อ = ต้องสร้างแอปใหม่และทำทุกอย่างใหม่หมด
