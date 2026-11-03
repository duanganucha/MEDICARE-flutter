# คู่มือ deploy Flutter app ขึ้น App Store

บันทึกจากการส่ง **MEDICARE** ขึ้น App Store จริง (ต.ค. 2026)
เขียนไว้ให้แอปตัวอื่นลอกตามได้ — ทุกขั้นที่เขียนคือขั้นที่ทำแล้วผ่านจริง
รวมถึงจุดที่ **ติด** และวิธีแก้

> ค่าทั้งหมดในเอกสารนี้เป็นของ MEDICARE เปลี่ยนเป็นของแอปคุณก่อนใช้

---

## สารบัญ

1. [ภาพรวม — ต้องมีอะไรบ้าง](#1-ภาพรวม)
2. [เตรียม API key (ทำครั้งเดียวต่อ account)](#2-เตรียม-api-key)
3. [ตั้งค่าโปรเจกต์ iOS](#3-ตั้งค่าโปรเจกต์-ios)
4. [สร้าง app record](#4-สร้าง-app-record)
5. [Build + upload](#5-build--upload)
6. [กรอกข้อมูลใน App Store Connect](#6-กรอกข้อมูลใน-app-store-connect)
7. [ส่งรีวิว](#7-ส่งรีวิว)
8. [ปัญหาที่เจอจริงและวิธีแก้](#8-ปัญหาที่เจอจริงและวิธีแก้)
9. [เช็กสถานะผ่าน API](#9-เช็กสถานะผ่าน-api)

---

## 1. ภาพรวม

### ต้องมี

| สิ่งที่ต้องมี | หมายเหตุ |
|---|---|
| Apple Developer Program | **$99/ปี** — ไม่มีไม่สามารถส่งขึ้น App Store ได้ |
| เครื่อง **macOS** + Xcode | build iOS บน Windows/Linux ไม่ได้ |
| App Store Connect API key (.p8) | ใช้ upload + เรียก API |
| Bundle ID | **เปลี่ยนไม่ได้** หลังสร้าง app record |

### เวลาที่ใช้จริง

| ขั้น | เวลา |
|---|---|
| ตั้งค่าครั้งแรก | 1–2 ชม. |
| build + upload | 10–20 นาที |
| Apple ประมวลผล build | 5–30 นาที |
| **รีวิว** | Apple บอก "ไม่เกิน 48 ชม." |

---

## 2. เตรียม API key

> ทำครั้งเดียวต่อ Apple account ใช้ได้กับทุกแอป

### 2.1 สร้าง key

1. ไป [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Users and Access** → **Integrations** → **App Store Connect API**
2. กด **+** → ตั้งชื่อ → Access = **App Manager**
3. โหลดไฟล์ `.p8` — **โหลดได้ครั้งเดียวเท่านั้น** พลาดแล้วต้องสร้างใหม่
4. จดไว้ 3 ค่า:
   - **Key ID** เช่น `6ZFTG727H4`
   - **Issuer ID** เช่น `69a6de87-937a-47e3-e053-5b8c7c11a4d1`
   - **Team ID** เช่น `97WC2DUVD3` (ดูที่ Membership)

### 2.2 เก็บ key

`xcrun altool` และ `xcodebuild` หา key จากตำแหน่งนี้เท่านั้น:

```sh
mkdir -p ~/.appstoreconnect/private_keys
mv ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/.appstoreconnect/private_keys/
chmod 600 ~/.appstoreconnect/private_keys/AuthKey_*.p8
```

> ⚠️ **ชื่อไฟล์ต้องเป็น `AuthKey_<KEY_ID>.p8` เป๊ะๆ** ไม่งั้นหาไม่เจอ

> 🔐 ไฟล์ `.p8` = ใครได้ไปจัดการแอปคุณได้ทั้งหมด
> **ห้าม** commit ลง git, ห้ามวางใน Desktop, ห้าม `cat` ลงหน้าจอตอนแชร์จอ

---

## 3. ตั้งค่าโปรเจกต์ iOS

### 3.1 Bundle ID

ต้องตรงกัน **3 ที่**:

```sh
# 1. ios/Runner.xcodeproj/project.pbxproj (มีหลายบรรทัด แก้ให้ครบ)
grep -n "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

```
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.yourapp;            ← ตัวแอป
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.yourapp.RunnerTests; ← test target
```

2. App record ใน App Store Connect
3. Provisioning profile

> 🚨 **เปลี่ยน Bundle ID ไม่ได้หลังสร้าง app record** คิดให้ดีก่อน
> ถ้าเปลี่ยน = ต้องสร้าง app ใหม่ทั้งหมด

### 3.2 Deployment target

Flutter รุ่นใหม่ต้องการ **iOS 15.0 ขึ้นไป** (ค่า default เดิม 13.0 จะ build ไม่ผ่าน)

แก้ **2 ที่** ให้ตรงกัน:

```sh
# ios/Podfile บรรทัดแรก
platform :ios, '15.0'
```

```sh
# ios/Runner.xcodeproj/project.pbxproj — มี 3 บรรทัด (Debug/Release/Profile)
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' \
  ios/Runner.xcodeproj/project.pbxproj
```

แล้วล้าง pod:

```sh
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

> ⚠️ **แก้ 2 ที่ยังไม่พอ** — ทุกครั้งที่ `flutter pub add` แพ็กเกจที่มีโค้ด
> iOS (เช่น `url_launcher`) pod ตัวใหม่จะกลับไปใช้ **13.0** ตาม default ของ
> Flutter แล้ว build พังอีก
>
> ปักหมุดใน `ios/Podfile` ให้จบ:
>
> ```ruby
> post_install do |installer|
>   installer.pods_project.targets.each do |target|
>     flutter_additional_ios_build_settings(target)
>     target.build_configurations.each do |config|
>       config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
>     end
>   end
> end
> ```
>
> ตรวจว่าได้ผล:
> ```sh
> grep -c "IPHONEOS_DEPLOYMENT_TARGET = 13.0" ios/Pods/Pods.xcodeproj/project.pbxproj
> # ต้องได้ 0
> ```

### 3.3 เวอร์ชัน

```yaml
# pubspec.yaml
version: 1.0.0+2
#        ^^^^^ ^
#        |     └─ build number — ต้อง +1 ทุกครั้งที่ upload (ซ้ำไม่ได้)
#        └─────── version string — ที่ผู้ใช้เห็น
```

### 3.4 ExportOptions.plist

สร้าง `ios/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>97WC2DUVD3</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>com.yourcompany.yourapp</key>
		<string>ชื่อ Provisioning Profile</string>
	</dict>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>uploadSymbols</key>
	<true/>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
</dict>
</plist>
```

> **ทำไมใช้ `manual` ไม่ใช้ `automatic`?**
> ถ้า Xcode ต่อ Apple ได้ `automatic` ง่ายกว่า แต่บางเครือข่าย (เช่น เน็ตโรงพยาบาล/
> องค์กรที่มี firewall) Xcode จะติด `NSURLErrorDomain -1009` แล้วหา profile ไม่เจอ
> `manual` + สร้าง profile ผ่าน API แก้ปัญหานี้ได้ — ดู [8.2](#82-no-profiles-found)

> `manageAppVersionAndBuildNumber = false` สำคัญ — ไม่งั้น Xcode จะไปแก้เลข
> build ให้เอง ทำให้ไม่ตรงกับ `pubspec.yaml`

---

## 4. สร้าง app record

> ⚠️ **API สร้าง app record ไม่ได้** ต้องทำผ่านเว็บเท่านั้น

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → **+** → **New App**
2. กรอก:

| ช่อง | ค่า |
|---|---|
| Platforms | iOS |
| Name | ชื่อที่แสดงบน App Store (ซ้ำกับแอปอื่นทั้งระบบไม่ได้) |
| Primary Language | ภาษาหลัก |
| Bundle ID | เลือกจาก list (ถ้าไม่มีให้สร้างที่ developer.apple.com → Identifiers) |
| SKU | รหัสภายใน ตั้งอะไรก็ได้ เช่น `medicare-2026` |

3. สร้างเสร็จ **จด App ID** (ตัวเลขใน URL)
   `https://appstoreconnect.apple.com/apps/[6824204699]/...`

---

## 5. Build + upload

### 5.1 ตรวจก่อน build

```sh
flutter analyze    # ต้อง "No issues found!"
flutter test       # ต้องผ่านหมด
```

### 5.2 Build + upload

ใช้สคริปต์ [`scripts/release-ios.sh`](scripts/release-ios.sh):

```sh
./scripts/release-ios.sh
```

สคริปต์ทำ 3 ขั้น:

```
1/3  flutter build ipa --export-options-plist=ios/ExportOptions.plist
     └─ ถ้าพัง → fallback ไป xcodebuild -exportArchive
2/3  xcrun altool --upload-app
3/3  รอ build ประมวลผล → ตั้ง usesNonExemptEncryption=false → ส่ง TestFlight
```

### 5.3 ทำเองทีละขั้น (ถ้าไม่ใช้สคริปต์)

```sh
# Build
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# Upload
xcrun altool --upload-app \
  -f build/ios/ipa/YourApp.ipa -t ios \
  --apiKey 6ZFTG727H4 \
  --apiIssuer 69a6de87-937a-47e3-e053-5b8c7c11a4d1
```

> 💡 **`usesNonExemptEncryption`** — ถ้าไม่ตั้งค่านี้ Apple จะถามทุกครั้งที่
> upload แล้ว build จะค้างไม่เข้า TestFlight
> แอปที่ใช้แค่ HTTPS ปกติ ตอบ `false` ได้
>
> ตั้งถาวรใน `ios/Runner/Info.plist` ก็ได้:
> ```xml
> <key>ITSAppUsesNonExemptEncryption</key>
> <false/>
> ```

---

## 6. กรอกข้อมูลใน App Store Connect

### 6.1 Screenshot — ขนาดที่ Apple บังคับ

| อุปกรณ์ | ขนาด (px) | จำเป็น? |
|---|---|---|
| iPhone 6.9" | **1320 × 2868** | ✅ บังคับ |
| iPad 13" | **2064 × 2752** | ✅ ถ้า support iPad |

> ถ้า **ไม่** support iPad ให้ตั้ง target เป็น iPhone only จะได้ไม่ต้องทำ

**วิธีถ่าย screenshot ให้ได้ขนาดเป๊ะ** — ใช้ simulator ที่ตรงรุ่น:

```sh
xcrun simctl list devices | grep -i "iPhone 16 Pro Max"
xcrun simctl boot "iPhone 16 Pro Max"
flutter run -d <device-id> --release
xcrun simctl io booted screenshot shot.png
```

> 💡 **เคล็ดลับ** — ถ้าแอปต้องกรอกข้อมูลก่อนถึงหน้าที่อยากถ่าย ให้เขียน
> entry point แยกที่ใส่ค่า default ไว้แล้ว (ดู [`lib/main_shots.dart`](lib/main_shots.dart))
> แล้ว boot ตรงเข้าหน้านั้นเลย:
> ```sh
> flutter run --dart-define=SHOT=noac_result
> ```
> เชื่อถือได้กว่าการสั่งกดปุ่มทีละขั้นมาก

### 6.2 App Privacy

ตอบตามจริง ถ้าแอปไม่เก็บข้อมูลเลยให้เลือก **"Data Not Collected"**

> ⚠️ ต้องกด **Publish** ด้วย ไม่งั้นจะค้างเป็น draft แล้วส่งรีวิวไม่ได้

### 6.3 Age Rating

ตอบแบบสอบถามตามจริง

> 🚨 **ข้อควรระวังสำหรับแอปการแพทย์**
> ถ้าตอบ **"Medical or Treatment Information" = Frequent/Intense** ตามจริง
> จะได้เรต **17+** และ Apple จะเด้งคำถามเพิ่ม **"Regulated Medical Device Declaration"**
> ซึ่งโยงถึงการขึ้นทะเบียน FDA/อย.
>
> ถ้าแอปเป็นแค่เครื่องมือช่วยคำนวณ ไม่ใช่เครื่องมือแพทย์ตามกฎหมาย → ตอบ **No**
> แต่ **ควรให้เจ้าของแอปตัดสินใจเอง** เพราะเป็นการประกาศทางกฎหมาย

### 6.4 รายการที่ต้องครบก่อนส่งรีวิว

- [ ] Screenshot (iPhone 6.9" + iPad 13" ถ้า support)
- [ ] Description, Keywords, Support URL
- [ ] **Privacy Policy URL** (ต้องเข้าถึงได้จริง — ดู [8.5](#85-privacy-policy-url))
- [ ] Category
- [ ] Age Rating
- [ ] **App Privacy** (กด Publish แล้ว)
- [ ] **Content Rights** — มีเนื้อหาของบุคคลที่สามหรือไม่
- [ ] **Pricing** — ฟรีก็ต้องเลือก $0.00
- [ ] **App Availability** — เลือกประเทศ
- [ ] Build (แนบจาก TestFlight)
- [ ] Copyright เช่น `2026 ชื่อคุณ`
- [ ] Review contact (ชื่อ, เบอร์, อีเมล)

---

## 7. ส่งรีวิว

1. หน้า version → **Add for Review**
2. ตรวจ **Draft Submission** ว่าขึ้น "Item Ready to Submit"
3. กด **Submit for Review**
4. ได้ `1 Item Submitted` → สถานะเปลี่ยนเป็น **Waiting for Review**

### Release option

| ตัวเลือก | ผล |
|---|---|
| **Automatically release** | อนุมัติแล้วขึ้นทันที |
| **Manually release** | อนุมัติแล้วรอคุณกดเอง |
| Scheduled | กำหนดวันเวลา |

> 💡 แอปใหม่ที่ยังไม่มีใครลองใช้จริง → **Manually release** ปลอดภัยกว่า
> จะได้ทดสอบบนเครื่องจริงก่อนปล่อยให้คนทั่วไป

---

## 8. ปัญหาที่เจอจริงและวิธีแก้

### 8.1 `IPHONEOS_DEPLOYMENT_TARGET 13.0 is not supported`

Flutter/pod รุ่นใหม่ต้องการ 15.0+ → แก้ทั้ง `Podfile` และ `project.pbxproj` (ดู [3.2](#32-deployment-target))

### 8.2 `No profiles found` / `NSURLErrorDomain -1009`

**อาการ:** `flutter build ipa` ฟ้องหา provisioning profile ไม่เจอ
**สาเหตุ:** Xcode ต่อ Apple ไม่ได้ (firewall / เน็ตองค์กร)

**แก้:** สร้าง profile ผ่าน API แล้ว export แบบ manual

```sh
./scripts/setup-ios-signing.sh
```

สคริปต์จะ:
1. เรียก App Store Connect API สร้าง/ดึง provisioning profile
2. ติดตั้งลง `~/Library/MobileDevice/Provisioning Profiles/`
3. ตั้ง `signingStyle: manual` ใน ExportOptions.plist

### 8.3 Build number ซ้ำ

```
ERROR ITMS-4236: The bundle version must be higher than...
```

**แก้:** เพิ่มเลขหลัง `+` ใน `pubspec.yaml` → `1.0.0+3`

> Build number ซ้ำไม่ได้ **แม้จะลบ build เดิมทิ้งแล้ว**

> 🪤 **กับดัก: log ปนกันระหว่าง altool หลายตัว — อย่าเพิ่งเชื่อว่า upload fail**
>
> ถ้ารันสคริปต์ค้างไว้แล้วรันซ้ำ (หรือตัวเก่าไม่ตายจริง) altool หลายตัว
> จะเขียนลง log ไฟล์เดียวกัน **สลับบรรทัดกันมั่ว** บรรทัดเดียวอาจมี
> timestamp สองช่วงเวลาติดกัน แบบนี้:
> ```
> Running altool at path2026-11-03 19:54:42 ERROR: ... 2026-11-03 19:56:13 ERROR: ...
> ```
> ตอนทำ MEDICARE อ่าน error `bundle version must be higher` ของตัวที่ตายแล้ว
> นึกว่า upload พัง **ทั้งที่จริง upload สำเร็จ** บรรทัดจริงอยู่ล่างๆ ว่า
> `UPLOAD SUCCEEDED with no errors`
>
> **ตรวจให้ชัวร์ด้วย API อย่าตัดสินจาก log:**
> ```python
> requests.get("https://api.appstoreconnect.apple.com/v1/builds",
>     params={"filter[app]": APP_ID, "limit": 50,
>             "fields[builds]": "version,uploadedDate,processingState"},
>     headers=H, timeout=30)
> ```
> ถ้าเห็น build เลขใหม่ `VALID` = ขึ้นแล้ว จบ
>
> **และอย่ารัน `nohup ... &` ซ้อนใน background task** — ตัว wrapper จบทันที
> รายงาน exit 0 ส่วนสคริปต์จริงตายตามไปด้วย ให้รันสคริปต์ตรงๆ เป็น task เลย

### 8.4 Build ค้างไม่เข้า TestFlight

**สาเหตุ:** ยังไม่ตอบคำถาม export compliance
**แก้:** ตั้ง `usesNonExemptEncryption = false` (ดู [5.3](#53-ทำเองทีละขั้น-ถ้าไม่ใช้สคริปต์))

### 8.5 Privacy Policy URL

Apple **เปิดลิงก์จริง** ถ้าเข้าไม่ได้จะโดน reject

ใช้ GitHub Pages ฟรีได้:

```
repo/docs/privacy.html
→ Settings → Pages → Source: main /docs
→ https://<user>.github.io/<repo>/privacy.html
```

ตรวจก่อนส่งเสมอ:

```sh
curl -sS -o /dev/null -w "%{http_code}\n" https://yourname.github.io/yourrepo/privacy.html
# ต้องได้ 200
```

### 8.6 ถูก reject — Guideline 1.4.1 Safety: Physical Harm

> 🚨 **แอปการแพทย์โดนข้อนี้บ่อยที่สุด** — MEDICARE โดนจริงในรอบแรก

**ข้อความจาก Apple:**

> The app includes medical information but does not include citations for the
> medical information. Specifically, the app provides health or medical
> calculations in the app without citations, such as links to sources for this
> information. All apps with medical and health information should include
> citations to ensure users are provided accurate information.
>
> **Next Steps:** Include citations in the app of the sources of the
> recommendations or information, such as **links to those sources**. The
> citations should be easy for the user to find.

**สิ่งที่ Apple ต้องการ (ตีความจากข้อความ):**

| ไม่พอ | ผ่าน |
|---|---|
| เขียนชื่อแนวทางเป็น**ข้อความเฉยๆ** | **ลิงก์กดได้**ไปเอกสารต้นฉบับ |
| ซ่อนไว้ในหน้า About | อยู่**ใกล้ผลลัพธ์** หาเจอง่าย |
| ใส่แค่หน้าเดียว | **ทุกหน้า**ที่มีการคำนวณ |

**วิธีแก้ที่ใช้จริง** — ใส่ `url_launcher` แล้วทำ widget ลิงก์ไว้ท้ายทุกหน้าคำนวณ
(ดู `CitationLink` / `Citations` ใน [`lib/ui/widgets.dart`](lib/ui/widgets.dart))

**เลือก URL ที่เชื่อถือได้และ bot เปิดได้:**

```sh
# ตรวจก่อนใส่ในแอปเสมอ
curl -sS -o /dev/null -w "%{http_code}\n" -L -A "Mozilla/5.0" "<url>"
```

| แหล่ง | ใช้ได้ไหม |
|---|---|
| `pubmed.ncbi.nlm.nih.gov/<PMID>/` | ✅ เสถียรที่สุด |
| `who.int/publications/i/item/<ISBN>` | ✅ |
| `doi.org/...` | ⚠️ มัก redirect ไปสำนักพิมพ์ที่ตอบ 403 |
| `academic.oup.com` | ❌ 403 กับ bot |

> 💡 **ตรวจชื่อเรื่อง/ปี กับ NCBI ก่อนเขียนลงแอป** อย่าพิมพ์จากความจำ:
> ```sh
> curl -sS "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=33895845&retmode=json"
> ```
> ตอนทำ MEDICARE เจอว่าแนวทาง WHO TB เป็นปี **2022** ไม่ใช่ 2021

**แก้แล้วทำอะไรต่อ:** (ลำดับนี้สำคัญ — ทำผิดลำดับปุ่ม resubmit จะกดไม่ได้)

1. เพิ่ม build number (`1.0.0+2` → `1.0.0+3`)
2. build + upload ใหม่ รอจน build ขึ้นเป็น `VALID`
3. **สลับ build ในหน้า version ก่อน** ← ขั้นที่คนลืมบ่อยที่สุด
   หน้า *Distribution → iOS App 1.0* จะยัง**ผูกอยู่กับ build เก่าที่โดน reject**
   - เลื่อนไปหัวข้อ **Build** → เอาเมาส์ **hover** ที่แถว build
     (ปุ่มลบสีแดง ⊖ โผล่เฉพาะตอน hover — ไม่ hover จะไม่เห็นอะไรเลย)
   - กด ⊖ ลบ build เก่า → ปุ่ม **Add Build** โผล่ขึ้นมา
   - เลือก build ใหม่ → **Done** → **Save**
   - ตรวจว่า sidebar เปลี่ยนจาก 🔴 *Rejected* เป็น 🟡 *Prepare for Submission*
4. เขียนคำอธิบายใน **App Review Information → Notes** ของหน้า version
   (ไม่ใช่ Resolution Center — ดูกล่องด้านล่าง) แล้ว **Save**
5. กด **Update Review** → ระบบพาไปหน้า submission
   สถานะ item เปลี่ยนเป็น *Ready for Review* และปุ่ม
   **Resubmit to App Review** จะเปลี่ยนจากสีเทาเป็นสีฟ้า
6. กด **Resubmit to App Review** → header เปลี่ยนเป็น *Waiting for Review*

> ⚠️ **ตอบที่ไหน: Notes ไม่ใช่ Resolution Center**
> ลิงก์ *Reply to App Review* ในหน้า submission มีไว้**ถาม/ชี้แจงระหว่างรอ**
> ไม่ใช่ช่องทางส่งของกลับ การ resubmit จริงไปกับ
> **App Review Information → Notes** ของ version
> เขียนแบบ **เติมข้างบนของเดิม** อย่าลบวิธีทดสอบที่เคยเขียนไว้ —
> reviewer ยังต้องใช้ (จำกัด 4000 ตัวอักษร ตัวเลขใต้ช่องคือ**จำนวนที่เหลือ**
> ไม่ใช่จำนวนที่ใช้ไป)
>
> เนื้อหาที่ควรมีใน Notes:
> - บอกตรงๆ ว่า build ก่อนโดน reject เพราะอะไร build ใหม่แก้อะไร
> - **คัดลอกรายการอ้างอิงพร้อม URL มาแปะให้ครบ** reviewer จะได้ไม่ต้องหาเอง
> - บอก**ตำแหน่ง**ที่จะเห็น (เช่น "อยู่ใต้ผลลัพธ์ เลื่อนลงล่างสุด")

> 📌 **submission ID เดิมถูกใช้ซ้ำ** ไม่ได้สร้าง submission ใหม่
> ดังนั้นข้อความ reject เดิมของ Apple จะยังค้างอยู่ในหน้านั้นหลัง resubmit — ปกติ

**ตรวจผลด้วย API ไม่ใช่ดูแค่ UI:**

```python
r = requests.get(
    "https://api.appstoreconnect.apple.com/v1/apps/<APP_ID>/appStoreVersions",
    params={"limit": 3}, headers=H, timeout=30)
# PREPARE_FOR_SUBMISSION → ยังไม่ส่ง
# WAITING_FOR_REVIEW     → ส่งสำเร็จแล้ว
```

> ⚠️ endpoint `/appStoreVersions/<id>/build` กับ `appStoreReviewDetail`
> **ค้างหรือตอบ 500 บ่อย** อย่าเอามาเป็นตัวตัดสิน ใช้ `appStoreState` พอ
> และใส่ `timeout=` เสมอ ไม่งั้นสคริปต์ค้างยาว
> (macOS ไม่มีคำสั่ง `timeout` ให้ใช้ — ต้องใส่ใน requests เอง)

### 8.7 Icon มี alpha channel

```
ERROR ITMS-90717: Invalid App Store Icon
```

Icon 1024×1024 สำหรับ App Store **ห้ามมี alpha channel**

```sh
# ตรวจ
sips -g hasAlpha icon-1024.png

# แก้ — แปะลงพื้นขาว
sips -s format png --setProperty format png icon.png --out flat.png
```

---

## 9. เช็กสถานะผ่าน API

เช็กสถานะได้โดยไม่ต้องเปิดเว็บ:

```python
#!/usr/bin/env python3
# pip install pyjwt cryptography
import time, json, urllib.request, jwt

KEY_ID = "6ZFTG727H4"
ISSUER = "69a6de87-937a-47e3-e053-5b8c7c11a4d1"
APP    = "6824204699"

priv = open(f"{__import__('os').environ['HOME']}"
            f"/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8").read()
tok = jwt.encode({"iss": ISSUER, "exp": int(time.time()) + 1200,
                  "aud": "appstoreconnect-v1"},
                 priv, algorithm="ES256",
                 headers={"kid": KEY_ID, "typ": "JWT"})

req = urllib.request.Request(
    f"https://api.appstoreconnect.apple.com/v1/apps/{APP}/appStoreVersions?limit=3",
    headers={"Authorization": "Bearer " + tok})

for v in json.load(urllib.request.urlopen(req))["data"]:
    a = v["attributes"]
    print(f"{a['versionString']}  {a.get('appStoreState')}  {a.get('releaseType')}")
```

ผลลัพธ์:

```
1.0  WAITING_FOR_REVIEW  AFTER_APPROVAL
```

### สถานะที่เจอบ่อย

| สถานะ | ความหมาย |
|---|---|
| `PREPARE_FOR_SUBMISSION` | ยังกรอกไม่ครบ |
| `WAITING_FOR_REVIEW` | ส่งแล้ว รอคิว |
| `IN_REVIEW` | กำลังรีวิว |
| `PENDING_DEVELOPER_RELEASE` | อนุมัติแล้ว รอกด release |
| `READY_FOR_SALE` | ขึ้น App Store แล้ว |
| `REJECTED` | ถูกปฏิเสธ — อ่านเหตุผลใน Resolution Center |

---

## ภาคผนวก: checklist ย่อ

```
□ Apple Developer Program ($99/ปี)
□ สร้าง API key → ~/.appstoreconnect/private_keys/AuthKey_XXX.p8
□ Bundle ID ตรงกันทุกที่
□ IPHONEOS_DEPLOYMENT_TARGET = 15.0 (Podfile + pbxproj)
□ ExportOptions.plist
□ สร้าง app record บนเว็บ → จด App ID
□ flutter analyze + flutter test ผ่าน
□ ./scripts/release-ios.sh
□ Screenshot 1320×2868 (+ 2064×2752 ถ้า iPad)
□ Privacy Policy URL เช็ค curl ได้ 200
□ App Privacy → Publish
□ Content Rights / Pricing / Availability
□ Add for Review → Submit for Review
```

---

## อ้างอิงไฟล์จริงในโปรเจกต์นี้

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| [`scripts/release-ios.sh`](scripts/release-ios.sh) | build + upload + ส่ง TestFlight |
| [`scripts/setup-ios-signing.sh`](scripts/setup-ios-signing.sh) | สร้าง provisioning profile ผ่าน API |
| [`ios/ExportOptions.plist`](ios/ExportOptions.plist) | ตั้งค่า export |
| [`lib/main_shots.dart`](lib/main_shots.dart) | entry point สำหรับถ่าย screenshot |
| [`store/LISTING.md`](store/LISTING.md) | ข้อความสำหรับหน้าร้าน |
| [`store/RUN-THESE.md`](store/RUN-THESE.md) | บันทึกขั้นตอนที่ทำจริง |
