# MEDICARE (Flutter)

เครื่องมือช่วยคำนวณขนาดยาสำหรับเภสัชกร — พอร์ตจาก PWA
[khwankhwann123.github.io/MEDICARE](https://khwankhwann123.github.io/MEDICARE/)
มาเป็นแอป Flutter (Android / iOS / Web / macOS)

> **ต้นแบบสำหรับทดสอบ — ห้ามใช้สั่งยาหรือปรับยาจริง**
> แสดงขนาดยาตามตารางอ้างอิงเพื่อประกอบการพิจารณาเท่านั้น

## ฟังก์ชัน

- **NOACs (AF)** — คำนวณ CrCl (Cockcroft–Gault) แล้วเทียบขนาดยา
  apixaban / rivaroxaban / edoxaban / dabigatran ตาม 2021 EHRA Practical Guide
- **วัณโรค (TB)** — ผู้ใหญ่: เลือกเม็ดยาจากความแรงที่มีในคลัง;
  เด็ก: ขนาด mg/kg และปริมาตร INH syrup

## โครงสร้าง

```
lib/
  logic/        # ตรรกะคลินิกล้วน ไม่มี import ของ Flutter → unit-test ได้
    noac.dart   # Cockcroft–Gault + เกณฑ์ลดขนาดยาทั้ง 4 ตัว
    tb.dart     # การเลือกเม็ดยา + ขนาดตามน้ำหนัก
  ui/
    theme.dart        # Material 3 + DoseColors (พอร์ตจาก CSS custom properties)
    motion.dart       # ชุด animation ที่ใช้ร่วมกันทั้งแอป
    widgets.dart      # AppCard / DrugCard / StatBox / WarningBanner
    splash_page.dart  # splash ที่มี animation
    noac_page.dart
    tb_page.dart
```

ตรรกะคลินิกแยกจาก UI ทั้งหมด เพื่อให้ทดสอบและตรวจทานได้โดยไม่ต้องเปิดแอป

## ธีมสี

ปุ่มวงกลมมุมขวาบนของ header สลับระหว่าง **ม่วง/พีช** (ค่าเริ่มต้น) กับ **เขียว** (ชุดสีเดิมจากเว็บ)
จุดสีในปุ่มคือสีที่จะเปลี่ยนไป สีการ์ดผลลัพธ์ยา (เขียว/เหลือง/แดง) **ไม่เปลี่ยนตามธีม**
เพราะเป็นรหัสสีทางคลินิก — อยู่ใน `DoseColors` ที่ [lib/ui/theme.dart](lib/ui/theme.dart)

## รัน

```sh
flutter pub get
flutter run                    # เลือก device
flutter test                   # 49 tests
flutter build apk --release
flutter build web --release
```

## การตรวจสอบความถูกต้อง

ผลการคำนวณถูกเทียบกับ JavaScript ต้นฉบับแบบบรรทัดต่อบรรทัด:
**896 เคส NOACs + 12 เคส TB ผู้ใหญ่ + 9 เคส TB เด็ก → ค่าที่คำนวณได้ 8,579 บรรทัด ตรงกันทั้งหมด**
ครอบคลุมจุดหัวเลี้ยวหัวต่อ (CrCl 15/29/30/50/95, น้ำหนัก 60–61 กก., SCr 1.49–1.5, อายุ 79–80)

## Splash screen

ลำดับ animation (คุมด้วย controller เดียว 2.6 วินาที ใน [lib/ui/splash_page.dart](lib/ui/splash_page.dart)):
แคปซูลลอยเข้าจากมุม → กล่องไอคอนเด้งขึ้นพร้อมกากบาทวาดทีละเส้น → วงแหวนกระเพื่อม 2 ชั้น →
ตัวอักษร MEDICARE โผล่ทีละตัว → tagline และแถบ progress → ทั้งหมดลอยขึ้นแล้วจางเข้าแอป

Native splash ของ Android (ก่อน Flutter บูต) ใช้สีเดียวกัน จึงไม่มีจอขาวแวบ

## ไอคอนแอป

ใช้ **adaptive icon** (`mipmap-anydpi-v26/ic_launcher.xml`) แยก 2 เลเยอร์:
พื้นชมพูเต็มกรอบ + แคปซูลไขว้บนพื้นโปร่งใส ทำให้ launcher ครอปเป็นวงกลมได้เต็มวงเหมือนแอปอื่น
ถ้าใช้ไอคอนสี่เหลี่ยมอย่างเดียว launcher จะย่อทั้งภาพแล้วเหลือขอบ — เป็นสาเหตุที่ไอคอนเคยดูเล็ก

ขนาดแคปซูลคิดจากระยะจริงของแคปซูลแนวทแยง `hypot(L/2, W/2) + offset·√2`
ต้องไม่เกินรัศมี safe zone (66/108 ของเลเยอร์) ปัจจุบันใช้ scale 0.46 → เหลือระยะกันชน 1.3px

## หมายเหตุการพอร์ต

- `alert()` → `SnackBar`
- CSS `border-left` สีต่างด้าน → แถบสีเป็น widget ข้างเนื้อหา
  (Flutter วาด `Border` ที่สีแต่ละด้านไม่เท่ากันพร้อม `borderRadius` ไม่ได้ — จะ throw ตอน paint)
- ฟอนต์ IBM Plex Sans Thai ฝังมากับแอป (OFL) จึงใช้ได้ออฟไลน์เต็มรูปแบบ
- ความแรงเม็ดยาในคลัง (INH 100; RIF 300/450; PZA 500; EMB 400/500)
  อยู่ใน `adultRegimen()` ที่ [lib/logic/tb.dart](lib/logic/tb.dart) — แก้ที่เดียว
