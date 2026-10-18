# ขั้นตอน Deploy

> ทำตามลำดับ: GitHub → Play Store → App Store
> ส่วนที่ต้องทำเองคือสิ่งที่ต้องใช้บัญชี รหัสผ่าน หรือการจ่ายเงิน

---

## สถานะตอนนี้

| สิ่งที่เตรียมไว้แล้ว | ที่อยู่ |
|---|---|
| APK เซ็นแล้ว | `build/app/outputs/flutter-apk/app-release.apk` |
| App Bundle (ไฟล์ที่ Play ต้องใช้) | `build/app/outputs/bundle/release/app-release.aab` |
| iOS app (ยังไม่เซ็น) | `build/ios/iphoneos/Runner.app` |
| เว็บ | `build/web/` |
| Keystore | `android/upload-keystore.jks` + `android/key.properties` |
| ไอคอน + feature graphic | `store/assets/` |
| Screenshot 5 ภาพ | `store/assets/screenshots/` |
| ข้อความลงสโตร์ | `store/LISTING.md` |
| นโยบายความเป็นส่วนตัว | `docs/privacy.html`, `docs/privacy-en.html` |

---

## ⚠ สำคัญที่สุด: สำรอง keystore

`android/upload-keystore.jks` คือกุญแจที่ผูกกับแอปตลอดชีวิต
**ถ้าหายจะอัปเดตแอปตัวเดิมบน Play ไม่ได้อีกเลย** ต้องสร้างแอปใหม่ทั้งหมด

ทำตอนนี้เลย:
1. คัดลอก `android/upload-keystore.jks` และ `android/key.properties`
   ไปเก็บที่ปลอดภัยอย่างน้อย 2 ที่ (เช่น Google Drive ส่วนตัว + USB)
2. ไฟล์ทั้งสองถูกกันไม่ให้ขึ้น git แล้ว — **อย่าเอาขึ้น GitHub เด็ดขาด**

ลายนิ้วมือของกุญแจ (ไว้เทียบภายหลัง):
```
SHA-256: D6:8C:4C:15:61:9D:CC:81:A9:B1:B0:45:6A:1C:D3:E5:BB:C9:A1:72:53:E9:0A:82:64:10:23:C0:4F:25:25:8F
```

---

## 1. GitHub + หน้านโยบาย

```sh
# สร้าง repo บน github.com ก่อน แล้ว:
git remote add origin https://github.com/duanganucha/MEDICARE-flutter.git
git branch -M main
git push -u origin main
```

เปิด GitHub Pages: **Settings → Pages → Source: Deploy from a branch
→ Branch: `main`, Folder: `/docs`** → Save

รอสักครู่ จะได้ลิงก์นโยบาย:
```
https://duanganucha.github.io/MEDICARE-flutter/privacy.html
```
เก็บลิงก์นี้ไว้ ต้องกรอกทั้งสองสโตร์

### ถ้าอยากให้เปิดตัวแอปบนเว็บได้ด้วย
```sh
flutter build web --release --base-href /MEDICARE-flutter/
# แล้ว copy build/web/* ไปไว้ใน docs/ หรือใช้ branch gh-pages
```

---

## 2. Google Play Store

### 2.1 สมัคร
- สมัคร Play Console: https://play.google.com/console — **ค่าสมัคร $25 ครั้งเดียว**
- ถ้าลงในนามโรงพยาบาล ให้เลือกบัญชีแบบ **organization**
  (ต้องมีเอกสารยืนยันตัวตน ใช้เวลาตรวจ 2–3 วัน)

### 2.2 สร้างแอป
Create app → ชื่อ `MEDICARE` → ภาษาไทย → App → Free

### 2.3 อัปโหลด
- Production → Create new release
- อัปโหลด `build/app/outputs/bundle/release/app-release.aab`
- **ให้ Google จัดการกุญแจ (Play App Signing)** — ตอบรับเมื่อระบบถาม
  ตัว `upload-keystore.jks` จะกลายเป็นกุญแจสำหรับอัปโหลดเท่านั้น

### 2.4 กรอกข้อมูล
คัดลอกจาก `store/LISTING.md` ทุกช่อง และอัปโหลด:
- ไอคอน: `store/assets/icon-512-play.png`
- Feature graphic: `store/assets/feature-1024x500.png`
- Screenshot: ทั้ง 5 ภาพใน `store/assets/screenshots/`
- Privacy policy: ลิงก์จากข้อ 1

### 2.5 แบบสอบถามที่ต้องตอบ
- **Data safety** → ตอบว่าไม่เก็บข้อมูล (ตารางใน `LISTING.md`)
- **Content rating** → ตอบตามจริง จะได้เรต "ทุกวัย"
- **Target audience** → เลือก 18+ (เป็นเครื่องมือสำหรับบุคลากรการแพทย์)
- **Health apps declaration** → ประกาศว่าเป็นเครื่องมือช่วยคำนวณ
  ไม่ใช่เครื่องมือแพทย์ ไม่วินิจฉัยโรค

> ⚠ แอปกลุ่มสุขภาพมักถูกตรวจเข้มกว่าปกติ ข้อความ disclaimer
> ที่อยู่ในแอปและในนโยบายช่วยให้ผ่านง่ายขึ้น

### 2.6 ส่งตรวจ
Send for review → รอ 1–7 วัน

---

## 3. Apple App Store

### 3.1 สมัคร
- Apple Developer Program: https://developer.apple.com/programs/
  **$99 ต่อปี** (ไม่ใช่จ่ายครั้งเดียว)
- ถ้าลงในนามโรงพยาบาล ต้องมีหมายเลข D-U-N-S ของหน่วยงาน (ขอฟรี ใช้เวลาราว 2 สัปดาห์)

### 3.2 ตั้งค่า signing
```sh
open ios/Runner.xcworkspace
```
ใน Xcode: เลือก target **Runner** → **Signing & Capabilities**
→ ติ๊ก *Automatically manage signing* → เลือก Team ของคุณ

### 3.3 สร้างแอปใน App Store Connect
https://appstoreconnect.apple.com → My Apps → **+** → New App
- Bundle ID: `th.go.sskhospital.medicare`
- ชื่อ: `MEDICARE`
- ภาษาหลัก: Thai

### 3.4 Build แล้วส่งขึ้น
```sh
flutter build ipa --release
```
ได้ไฟล์ที่ `build/ios/ipa/*.ipa` → เปิดด้วย **Transporter**
(โหลดฟรีจาก Mac App Store) แล้วส่งขึ้น

หรือส่งตรงจาก Xcode: Product → Archive → Distribute App

### 3.5 Screenshot ที่ Apple ต้องการ
Apple บังคับขนาดเฉพาะ ต้องถ่ายจาก simulator ที่มีอยู่แล้วในเครื่อง:
```sh
# iPhone 17 Pro Max (ได้ขนาด 6.9" ที่ Apple ต้องการ)
flutter run --release -d "iPhone 17 Pro Max"
# กด Cmd+S ใน simulator เพื่อบันทึกภาพ หรือ:
xcrun simctl io booted screenshot ~/Desktop/shot.png
```
ต้องมีอย่างน้อย 3 ภาพ

### 3.6 กรอกข้อมูลและส่ง
- ใช้ข้อความจาก `store/LISTING.md`
- **App Privacy** → ตอบ "Data Not Collected"
- Export compliance → ตอบ **No** (ตั้ง `ITSAppUsesNonExemptEncryption=false` ไว้แล้ว)
- Submit for Review → รอ 1–3 วัน

> ⚠ Apple มีกฎเฉพาะสำหรับแอปการแพทย์ (App Review Guideline 1.4.1)
> ต้องระบุชัดว่าใครเป็นผู้พัฒนาและข้อมูลอ้างอิงมาจากไหน — ใส่ไว้ใน
> คำอธิบายแล้ว ถ้าถูกถามเพิ่ม ให้ชี้ไปที่ EHRA 2021 guideline

---

## 4. เวลาจะออกเวอร์ชันใหม่

แก้เลขใน `pubspec.yaml`:
```yaml
version: 1.0.1+2    # 1.0.1 = เลขที่ผู้ใช้เห็น, +2 = build number ต้องเพิ่มทุกครั้ง
```
แล้ว build ใหม่:
```sh
flutter build appbundle --release   # Play
flutter build ipa --release         # App Store
```

---

## สิ่งที่ยังต้องตัดสินใจ

1. **ลงในนามใคร** — ส่วนตัว หรือโรงพยาบาลศรีสะเกษ
   ถ้าเป็นโรงพยาบาลต้องใช้เอกสารหน่วยงานและใช้เวลานานกว่า
2. **อีเมลติดต่อ** — ตอนนี้ใช้ `duanganucha@hotmail.com` ทั้งในนโยบายและสโตร์
   จะเปลี่ยนเป็นอีเมลหน่วยงานได้ที่ `docs/privacy*.html` และ `store/LISTING.md`
3. **ชื่อ repo** — ต้องรู้ก่อนถึงจะเติมลิงก์นโยบายให้ครบได้
