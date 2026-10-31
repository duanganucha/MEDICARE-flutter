# คู่มือ deploy Flutter app ขึ้น Google Play

บันทึกจากการส่ง **MEDICARE** ขึ้น Play Store จริง (ต.ค. 2026)
เขียนไว้ให้แอปตัวอื่นลอกตามได้ — ทุกขั้นที่เขียนคือขั้นที่ทำแล้วผ่านจริง
รวมถึงจุดที่ **ติด** และวิธีแก้

> คู่มือ iOS อยู่ที่ [`guide_deploy_ios.md`](guide_deploy_ios.md)
> ค่าทั้งหมดในเอกสารนี้เป็นของ MEDICARE เปลี่ยนเป็นของแอปคุณก่อนใช้

---

## สารบัญ

1. [ภาพรวม](#1-ภาพรวม)
2. [สร้าง keystore](#2-สร้าง-keystore--สำคัญที่สุด)
3. [ตั้งค่า Gradle](#3-ตั้งค่า-gradle)
4. [ไอคอน adaptive](#4-ไอคอน-adaptive)
5. [Build AAB](#5-build-aab)
6. [สร้างแอปใน Play Console](#6-สร้างแอปใน-play-console)
7. [อัปโหลดผ่าน API](#7-อัปโหลดผ่าน-api)
8. [กรอก declaration ครบ 10 ข้อ](#8-กรอก-declaration-ครบ-10-ข้อ)
9. [5 ขั้นที่ซ่อนอยู่ก่อนกดส่งรีวิวได้](#9-5-ขั้นที่ซ่อนอยู่ก่อนกดส่งรีวิวได้)
10. [ปัญหาที่เจอจริงและวิธีแก้](#10-ปัญหาที่เจอจริงและวิธีแก้)

---

## 1. ภาพรวม

### Play vs App Store ต่างกันตรงไหน

| | Play Store | App Store |
|---|---|---|
| ค่าสมัคร | **$25 ครั้งเดียว** | $99/ปี |
| เครื่องที่ build ได้ | ทุก OS | **macOS เท่านั้น** |
| เวลารีวิว | ไม่เกิน 7 วัน | ไม่เกิน 48 ชม. |
| ไฟล์ที่อัป | `.aab` | `.ipa` |
| Declaration | **10 ข้อ** | น้อยกว่า |
| จุดที่พลาดบ่อย | **ปุ่ม Submit ไม่ขึ้น** | profile หาไม่เจอ |

### เวลาที่ใช้จริง

| ขั้น | เวลา |
|---|---|
| ตั้งค่าครั้งแรก + keystore | 1 ชม. |
| build AAB | 3–5 นาที |
| กรอก declaration 10 ข้อ | **1–2 ชม.** (นานที่สุด) |
| **รีวิว** | ไม่เกิน 7 วัน |

---

## 2. สร้าง keystore — สำคัญที่สุด

> 🚨 **อ่านก่อน**
> Keystore คือกุญแจเซ็นแอป **หายแล้วอัปเดตแอปไม่ได้อีกตลอดชีวิต**
> ต้องสร้างแอปใหม่ เปลี่ยน package ใหม่ ผู้ใช้เดิมอัปเดตไม่ได้
> Google **กู้ให้ไม่ได้** ไม่มีข้อยกเว้น

### 2.1 สร้าง

```sh
mkdir -p ~/Documents/PrivateKeyStore/yourapp
cd ~/Documents/PrivateKeyStore/yourapp

keytool -genkey -v \
  -keystore upload-keystore.jks \
  -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

> ใช้ **PKCS12** (มาตรฐานปัจจุบัน) ไม่ใช่ JKS แบบเก่า
> `validity 10000` ≈ 27 ปี — ตั้งสั้นกว่านี้แล้วหมดอายุจะยุ่ง

### 2.2 ไฟล์ key.properties

```properties
# ~/Documents/PrivateKeyStore/yourapp/key.properties
storePassword=<รหัสที่ตั้งไว้>
keyPassword=<รหัสที่ตั้งไว้>
keyAlias=upload
storeFile=/Users/you/Documents/PrivateKeyStore/yourapp/upload-keystore.jks
```

```sh
chmod 600 ~/Documents/PrivateKeyStore/yourapp/*
```

### 2.3 กันหลุดลง git

```gitignore
# .gitignore
key.properties
*.jks
*.keystore
```

> ⚠️ เก็บ keystore **นอก** โฟลเดอร์โปรเจกต์ จะได้ไม่เผลอ commit

### 2.4 สำรอง — ทำเดี๋ยวนี้

```sh
cd ~/Documents/PrivateKeyStore
tar czf ~/Desktop/yourapp-keystore-backup.tgz yourapp/
chmod 600 ~/Desktop/yourapp-keystore-backup.tgz
```

แล้ว **ก๊อปออกนอกเครื่อง** (Drive / USB / password manager) **แล้วลบไฟล์บน Desktop ทิ้ง**

> ไฟล์นี้มีรหัสผ่านอยู่ข้างใน อย่าทิ้งไว้ในที่ที่คนอื่นเห็น

---

## 3. ตั้งค่า Gradle

`android/app/build.gradle.kts`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.yourcompany.yourapp"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

    defaultConfig {
        applicationId = "com.yourcompany.yourapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // ไม่มี keystore บนเครื่องนี้ — ใช้ debug key เพื่อให้ยังรันได้
                // แต่ห้ามเอาไฟล์นี้ขึ้นสโตร์
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}
```

> 🔑 **ต้องใช้ `rootProject.file(...)` ไม่ใช่ `file(...)`**
> `file()` มองจาก `android/app/` จะหา keystore ไม่เจอ

### ตรวจว่าเซ็นถูก key จริง

```sh
# ดู fingerprint ของ APK ที่ build ออกมา
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk | grep SHA-256

# เทียบกับ keystore
keytool -list -v -keystore ~/Documents/PrivateKeyStore/yourapp/upload-keystore.jks \
  -alias upload | grep SHA-256
```

**2 ค่านี้ต้องตรงกัน** ถ้าไม่ตรง = ยังเซ็นด้วย debug key อยู่ อัปขึ้น Play ไม่ได้

---

## 4. ไอคอน adaptive

### ทำไมไอคอนเราเล็กกว่าชาวบ้าน

ถ้าใส่แค่ `mipmap-*/ic_launcher.png` ธรรมดา Android รุ่นใหม่จะย่อให้เล็กลง
ต้องทำ **adaptive icon** (2 เลเยอร์) ถึงจะเต็มวงเหมือนแอปอื่น

```xml
<!-- android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml -->
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
```

### เรขาคณิตที่ต้องรู้

ภาพ adaptive icon ขนาด **108×108 dp** แต่ launcher crop เหลือ **72×72 dp**
ของสำคัญต้องอยู่ใน **safe zone วงกลมกลาง 66 dp**

```
┌─────────── 108 ───────────┐
│                           │  ← ขอบนี้โดน crop
│    ┌───── 72 ─────┐       │
│    │   ╭─ 66 ─╮   │       │  ← safe zone
│    │   │ LOGO │   │       │
│    │   ╰──────╯   │       │
│    └──────────────┘       │
└───────────────────────────┘
```

**สูตรเช็กว่าของล้นกรอบกลมไหม** (ถ้าวาดเอง บน canvas 432 px):

```
รัศมี safe zone = 66/108 × 432 ÷ 2 = 132 px

ระยะจากจุดกลางถึง "จุดไกลสุด" ของวัตถุ ≤ 132 px
```

จุดไกลสุดคำนวณจากรูปทรงจริงของวัตถุ เช่นวัตถุสี่เหลี่ยมที่เลื่อนออกจากกลาง:

```
√((ยาว/2)² + (กว้าง/2)²) + ระยะเลื่อน×√2  ≤ 132
```

> ตัวอย่างจริง: MEDICARE เป็นแคปซูลไขว้ 2 เม็ด ตอนแรกล้นออกนอกวงกลม
> ต้องไล่ย่อ scale ลงจนระยะไกลสุดต่ำกว่า 132 px (ลงเอยที่ scale 0.46)
>
> 💡 เลข scale ขึ้นกับรูปทรงของไอคอนคุณ **อย่าลอกไปใช้ตรงๆ** — ให้คำนวณ
> จากทรงของตัวเอง แล้วดูผลจริงด้วย `flutter build` + ดูบนเครื่อง

### สร้างไฟล์ทุกความละเอียด

```sh
for d in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  name=${d%:*}; size=${d#*:}
  sips -z $size $size icon-source.png \
    --out android/app/src/main/res/mipmap-$name/ic_launcher.png
done
```

---

## 5. Build AAB

```sh
flutter analyze     # ต้อง "No issues found!"
flutter test        # ต้องผ่านหมด
flutter build appbundle --release
```

ได้ไฟล์ที่ `build/app/outputs/bundle/release/app-release.aab`

### เวอร์ชัน

```yaml
# pubspec.yaml
version: 1.0.0+2
#        ^^^^^ ^
#        |     └─ versionCode — ต้อง +1 ทุกครั้งที่อัป (ซ้ำไม่ได้เด็ดขาด)
#        └─────── versionName — ที่ผู้ใช้เห็น
```

---

## 6. สร้างแอปใน Play Console

1. [play.google.com/console](https://play.google.com/console) → **Create app**
2. กรอกชื่อ / ภาษา / App or Game / Free or Paid
3. จด **App ID** จาก URL:
   `.../developers/[6965940949477567807]/app/[4975765791564943456]/...`
   ตัวแรก = developer ID, ตัวหลัง = app ID

> 🚨 **package name (`applicationId`) เปลี่ยนไม่ได้หลังอัป AAB ตัวแรก**
> คิดให้ดีก่อน — เปลี่ยน = สร้างแอปใหม่ทำทุกอย่างใหม่หมด
>
> หลีกเลี่ยง namespace ที่สื่อว่าเป็นหน่วยงานรัฐ (`th.go.*`) ถ้าไม่ได้รับมอบหมาย
> อย่างเป็นทางการ เพราะจะขัดกับ declaration "Government apps"

---

## 7. อัปโหลดผ่าน API

### 7.1 สร้าง service account

1. Play Console → **Setup** → **API access** → link Google Cloud project
2. Cloud Console → สร้าง service account → โหลด JSON key
3. กลับมา Play Console → **Users and permissions** → Invite ด้วยอีเมล service account
4. ให้สิทธิ์:

| สิทธิ์ | ใช้ทำอะไร |
|---|---|
| **Release to production** | อัป AAB |
| **Manage store presence** | แก้ store listing ผ่าน API |

> ⚠️ ถ้าไม่ติ๊ก **Manage store presence** จะ `upload()` รูปได้แต่ `commit()` **403**
> — ดู [10.2](#102-403-permission-denied-ตอน-commit)

### 7.2 สคริปต์อัปโหลด

ดู [`scripts/release-play.sh`](scripts/release-play.sh) ตัวอย่างแกนหลัก:

```python
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

PKG = "com.yourcompany.yourapp"
creds = service_account.Credentials.from_service_account_file(
    KEY, scopes=["https://www.googleapis.com/auth/androidpublisher"])
svc = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)
edits = svc.edits()

edit_id = edits.insert(packageName=PKG, body={}).execute()["id"]

vc = edits.bundles().upload(
    packageName=PKG, editId=edit_id,
    media_body=MediaFileUpload(aab, mimetype="application/octet-stream",
                               resumable=True, chunksize=5*1024*1024)
).execute()["versionCode"]

edits.tracks().update(
    packageName=PKG, editId=edit_id, track="production",
    body={"releases": [{
        "name": f"v{vc}", "versionCodes": [str(vc)],
        "releaseNotes": [{"language": "th-TH", "text": "เวอร์ชันแรก"}],
        "status": "draft",     # แอปที่ยังเป็น draft ใช้ completed ไม่ได้
    }]}).execute()

edits.commit(packageName=PKG, editId=edit_id).execute()
```

> 💡 **`status`** — แอปที่ยังไม่เคยเผยแพร่ ต้องใช้ `"draft"`
> ใส่ `"completed"` จะได้ 400 `"Only releases with status draft may be created on draft app"`

### 7.3 รหัสภาษาต้องตรง

```python
L = "th"      # ✅ ถูก
L = "th-TH"   # ❌ 400 "The requested language is not currently supported"
```

เช็กของจริงก่อน:

```python
print(edits.listings().list(packageName=PKG, editId=eid).execute())
# → {'listings': [{'language': 'th', 'title': '...'}]}
```

---

## 8. กรอก declaration ครบ 10 ข้อ

Play Console → **Policy and programs** → **App content**

> หา "App content" ไม่เจอ? อยู่ใน **Monitor and improve → Policy and programs**

ตัวอย่างคำตอบของแอปที่ทำงานออฟไลน์ ไม่เก็บข้อมูล ไม่มีโฆษณา:

| # | หัวข้อ | คำตอบ | เช็คจากอะไร |
|---|---|---|---|
| 1 | **Privacy policy** | URL | ต้องเปิดได้จริง |
| 2 | **Ads** | No | `pubspec.yaml` ไม่มี ad SDK |
| 3 | **Sign in details** | No | ไม่มี login/payment |
| 4 | **Content rating** | ทำแบบสอบถาม IARC | ได้ "All ages" |
| 5 | **Target audience** | 18+ | |
| 6 | **Data safety** | ไม่เก็บ ไม่แชร์ | ไม่มี uses-permission |
| 7 | **Advertising ID** | No | ไม่มี ad SDK |
| 8 | **Government apps** | No | ถ้าไม่ได้รับมอบหมายทางการ |
| 9 | **Financial features** | ไม่มี | |
| 10 | **Health apps** | เลือกตามจริง | |

### ตรวจจากโค้ดก่อนตอบ

อย่าเดา — เช็คจริง:

```sh
# มี ad / analytics SDK ไหม
grep -riE "admob|google_mobile_ads|firebase|analytics|facebook|appsflyer" \
  lib/ pubspec.yaml android/app/src/main/AndroidManifest.xml

# ขอ permission อะไรบ้าง
grep -i "uses-permission" android/app/src/main/AndroidManifest.xml
```

ถ้าไม่เจออะไรเลย = ตอบ "ไม่มี" ได้อย่างมั่นใจ

### ข้อที่ควรให้เจ้าของแอปตัดสินใจเอง

ข้อพวกนี้เป็นการประกาศทางกฎหมาย อย่าตอบแทน:

- **IARC Terms of Use** — ข้อตกลงผูกพัน
- **Government apps** — ตอบ Yes ต้องมีหลักฐาน
- **Health apps** — "Clinical decision support" มักโดนตรวจเข้มกว่า
  ถ้าแอปแค่คำนวณขนาดยา "Medication and treatment management" ตรงกว่า

---

## 9. 5 ขั้นที่ซ่อนอยู่ก่อนกดส่งรีวิวได้

> 🚨 **จุดที่ทำให้เสียเวลามากที่สุด**
> ทำ declaration ครบ 10 ข้อแล้ว ปุ่ม **"Send app for review" ยังกดไม่ได้**
> ขึ้นแค่ *"To send changes for review, complete the required steps in the app dashboard"*
> โดยไม่บอกว่าขาดอะไร

ต้องครบทั้ง 5 ข้อนี้:

| # | ขั้น | อยู่ที่ไหน |
|---|---|---|
| 1 | **App category** (เช่น Medical) | Grow users → Store presence → **Store settings** |
| 2 | **Contact email + website** | หน้าเดียวกัน |
| 3 | **Store listing → Review → AI asset declaration** | Store listings → Edit → Next |
| 4 | **เลือกประเทศ** (เริ่มต้น = **0**) | **Production → Countries / regions** |
| 5 | **Preview and confirm release** | Production → Releases → Edit release → Next → Save |

> ⚠️ **ข้อ 4 คือตัวบล็อกตัวจริง** — production track เริ่มต้นที่ 0 ประเทศ
> ไม่มีอะไรเตือน ต้องเข้าไปเลือกเอง (เลือกทั้งหมด = 178 ประเทศ)

> ⚠️ **ข้อ 2 กดแล้ว publish ทันที** ไม่เข้าคิวรีวิว — ข้อมูลจะขึ้นหน้า Play เลย
> ใส่อีเมลที่ให้คนทั่วไปเห็นได้ เบอร์โทรเป็น optional ไม่ต้องใส่ก็ได้

### AI asset declaration

คำถามใหม่ที่โผล่ตอน review store listing:

- **ถ่ายจอแอปจริง + วาดไอคอนด้วยโค้ด** → "Don't label assets"
- **generate ภาพด้วย AI** → ต้องติดป้าย

### ส่งรีวิว

ครบ 5 ข้อแล้ว ปุ่มจะเปลี่ยนเป็น **"Submit N changes for review"**

```
Changes not yet submitted for review   →   Changes in review
```

Google รัน quick check ~15 นาที แล้วส่งเข้าคิวรีวิวอัตโนมัติ

---

## 10. ปัญหาที่เจอจริงและวิธีแก้

### 10.1 บันทึกแล้วแต่ API อ่านเป็นค่าว่าง

**อาการ:** กด Save ทุกอย่างในเว็บแล้ว แต่เช็คผ่าน API เห็น listing/รูปเป็นว่าง

**สาเหตุ:** ของที่ Save เก็บเป็น **"Changes not yet submitted for review"**
ยังไม่ apply กับ listing จริง API อ่านค่า live เลยเห็นว่าง

**ไม่ใช่บั๊ก** — ต้องกด Submit for review ก่อนถึงจะมีผล

> 💡 อย่าเชื่อว่า "เสร็จแล้ว" เพราะเห็นคำว่า Saved — ไปดูหน้า
> **Publishing overview** ว่ายังค้างใน "not yet submitted" อยู่ไหม

### 10.2 403 PERMISSION_DENIED ตอน commit

**อาการ:** `images().upload()` ได้ sha1 กลับมาทุกไฟล์ แต่ `edits.commit()` ตอบ 403

**วิธีไล่หาสาเหตุ:**

| ทดสอบ | ผล |
|---|---|
| commit edit **ว่าง** | ✅ ผ่าน |
| commit ที่แก้ description | ❌ 403 |
| commit ที่มีรูป | ❌ 403 |

→ commit ว่างผ่าน แต่ commit ที่**เปลี่ยนอะไรจริง**ไม่ผ่าน = ขาดสิทธิ์

**แก้:** Play Console → Users and permissions → ติ๊ก **Manage store presence**

> ⚠️ อย่าตีความว่า "commit ผ่าน = มีสิทธิ์" — ลองด้วย edit ที่เปลี่ยนของจริง

### 10.3 อัปรูปผ่าน browser ไม่ได้

**อาการ:** ปุ่ม "Add assets" เปิด native file picker ที่ automation คุมไม่ได้

**แก้:** patch ให้ไม่เปิด dialog แล้วยัดไฟล์เข้า input โดยตรง

```js
// 1. กัน native picker ไม่ให้เปิด
if (!window.__patched) {
  window.__patched = true;
  const orig = HTMLInputElement.prototype.click;
  HTMLInputElement.prototype.click = function () {
    if (this.type === 'file') return;      // กลืน click ทิ้ง
    return orig.apply(this, arguments);
  };
}
// 2. กดปุ่ม "Add assets" → input ถูกสร้างใน DOM แต่ dialog ไม่เปิด
// 3. ยัดไฟล์เข้า input นั้น
```

> Play จะ **deduplicate** กับรูปที่เคยอัปผ่าน API ให้เอง ไม่ซ้ำซ้อน

### 10.4 400 "Only releases with status draft may be created on draft app"

แอปที่ยังไม่เคยเผยแพร่ใช้ `status: "completed"` ไม่ได้ → ใช้ `"draft"` (ดู [7.2](#72-สคริปต์อัปโหลด))

### 10.5 versionCode ซ้ำ

```
APK specifies a version code that has already been used
```

เพิ่มเลขหลัง `+` ใน `pubspec.yaml` → `1.0.0+3`

> ซ้ำไม่ได้แม้จะลบ release เดิมทิ้งแล้ว

### 10.6 APK เซ็นด้วย debug key

**อาการ:** อัปแล้วโดนปฏิเสธเรื่อง signature

**ตรวจ:**

```sh
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk | grep SHA-256
```

ถ้าไม่ตรงกับ keystore = `key.properties` ไม่ถูกอ่าน
→ เช็คว่าใช้ `rootProject.file(...)` แล้ว และไฟล์อยู่ที่ `android/key.properties`

### 10.7 XML comment พัง

```xml
<!-- ใช้ --bg เป็นสีพื้น -->   ← ❌ "--" ใน comment ผิด syntax
<!-- ใช้ bg เป็นสีพื้น -->     ← ✅
```

### 10.8 Store listing ไม่มีที่ให้กด "Create"

ถ้า API commit ไม่ผ่านตลอด ลองเช็คว่าเคยกด **"Create default store listing"**
ในคอนโซลหรือยัง — ถ้ายัง API จะแก้อะไรไม่ได้เลย

---

## ภาคผนวก: checklist ย่อ

```
□ สมัคร Play Console ($25)
□ สร้าง keystore (PKCS12) + key.properties
□ *** สำรอง keystore ออกนอกเครื่อง ***
□ .gitignore: key.properties, *.jks
□ build.gradle.kts ใช้ rootProject.file(...)
□ adaptive icon (safe zone 66/108)
□ flutter analyze + flutter test ผ่าน
□ flutter build appbundle --release
□ ตรวจ SHA-256 ตรงกับ keystore
□ สร้างแอปใน Play Console
□ service account + Manage store presence
□ อัป AAB (status=draft)
□ Store listing: ข้อความ + icon 512 + feature 1024×500 + screenshot 2–8
□ Declaration 10 ข้อ
□ ─── 5 ขั้นที่ซ่อนอยู่ ───
   □ App category
   □ Contact email + website (publish ทันที)
   □ AI asset declaration
   □ *** เลือกประเทศ (เริ่มต้น 0) ***
   □ Preview and confirm release
□ Submit N changes for review → "Changes in review"
```

---

## ขนาดรูปที่ Play บังคับ

| รูป | ขนาด | จำเป็น |
|---|---|---|
| App icon | **512 × 512** PNG | ✅ |
| Feature graphic | **1024 × 500** | ✅ |
| Phone screenshot | 16:9 หรือ 9:16, ด้านละ 320–3840 px | ✅ 2–8 ภาพ |

> ถ้าอยากให้แอปมีสิทธิ์ถูกโปรโมท ใส่ screenshot อย่างน้อย 4 ภาพ ด้านสั้น ≥ 1080 px
> ตัวอย่างที่ใช้จริง: **1080 × 2424**

---

## อ้างอิงไฟล์จริงในโปรเจกต์นี้

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| [`scripts/release-play.sh`](scripts/release-play.sh) | build + อัป AAB ผ่าน API |
| [`scripts/play-listing.py`](scripts/play-listing.py) | อัป store listing + รูปผ่าน API |
| [`android/app/build.gradle.kts`](android/app/build.gradle.kts) | ตั้งค่า signing + R8 |
| [`store/LISTING.md`](store/LISTING.md) | ข้อความสำหรับหน้าร้าน |
| [`store/RUN-THESE.md`](store/RUN-THESE.md) | บันทึกขั้นตอนที่ทำจริง + ปัญหาที่เจอ |
