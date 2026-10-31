import sys, os
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from googleapiclient.errors import HttpError

KEY = "/Users/duanganucha/Documents/PrivateKeyStore/hin-korat/hin-korat-0296ccd3d4b8.json"
PKG = "th.go.sskhospital.medicare"
LANG = "th"
ROOT = "/Users/duanganucha/Desktop/Rx_Apps/Rx_MEDICARE_flutter"
A = f"{ROOT}/store/assets"

FULL = """MEDICARE เป็นเครื่องมือช่วยคำนวณขนาดยาสำหรับเภสัชกรและบุคลากรทางการแพทย์
ออกแบบให้ใช้ง่ายข้างเตียงผู้ป่วย และทำงานได้โดยไม่ต้องต่ออินเทอร์เน็ต

■ ยาต้านการแข็งตัวของเลือดกลุ่ม NOACs (ผู้ป่วย AF)
• คำนวณค่า CrCl ด้วยสูตร Cockcroft–Gault
• เปรียบเทียบขนาดยาทั้ง 4 ตัวพร้อมกัน — apixaban, rivaroxaban,
  edoxaban และ dabigatran
• แสดงเหตุผลกำกับทุกขนาดยา ว่าเข้าเกณฑ์ลดขนาดข้อใดบ้าง
• เตือนเมื่อ CrCl ต่ำกว่าเกณฑ์ หรือเมื่อยาตัวนั้นไม่แนะนำให้ใช้
• อ้างอิง 2021 EHRA Practical Guide on the Use of NOACs in Patients with AF

■ ยาวัณโรค
• ผู้ใหญ่ (≥15 ปี): คำนวณขนาด HRZE ตามน้ำหนัก พร้อมเลือกจำนวนเม็ดยา
  จากความแรงที่มีในคลัง และบอกผลต่างจากขนาดเป้าหมาย
• เด็ก (<15 ปี): คำนวณขนาดตาม mg/kg และปริมาตร isoniazid syrup
  พร้อมจำนวนขวดต่อวัน

■ จุดเด่น
• ทำงานออฟไลน์ 100% ไม่ต้องต่อเน็ต
• ไม่เก็บข้อมูลผู้ป่วย ไม่ส่งข้อมูลออกนอกเครื่อง ไม่มีโฆษณา ไม่มี tracker
• รองรับโหมดสว่างและมืด พร้อมสลับชุดสีได้
• ภาษาไทยเต็มรูปแบบ

■ ข้อควรทราบ
แอปนี้เป็นเครื่องมือช่วยคำนวณเพื่อประกอบการพิจารณาเท่านั้น ไม่ใช่เครื่องมือแพทย์
และไม่ใช่คำสั่งการรักษา ผู้ใช้ต้องตรวจสอบกับฉลากยา แนวทางเวชปฏิบัติฉบับล่าสุด
และบริบทของผู้ป่วยแต่ละรายก่อนตัดสินใจทางคลินิกเสมอ"""

SHORT = "เครื่องมือช่วยเภสัชกรคำนวณขนาดยา NOACs และวัณโรค ทำงานออฟไลน์เต็มรูปแบบ"

creds = service_account.Credentials.from_service_account_file(
    KEY, scopes=["https://www.googleapis.com/auth/androidpublisher"])
svc = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)
edits = svc.edits()
eid = edits.insert(packageName=PKG, body={}).execute()["id"]
print("edit:", eid)

# 1. listing text
r = edits.listings().update(packageName=PKG, editId=eid, language=LANG, body={
    "language": LANG, "title": "MEDICARE",
    "shortDescription": SHORT, "fullDescription": FULL,
}).execute()
print("listing text OK:", r.get("title"), "| short:", len(SHORT), "full:", len(FULL))

# 2. images
IMAGES = [
    ("icon",             [f"{A}/icon-512-play.png"]),
    ("featureGraphic",   [f"{A}/feature-1024x500.png"]),
    ("phoneScreenshots", sorted(f"{A}/screenshots/{f}"
                               for f in os.listdir(f"{A}/screenshots")
                               if f.endswith(".png"))),
]
for itype, paths in IMAGES:
    try:
        edits.images().deleteall(packageName=PKG, editId=eid,
                                 language=LANG, imageType=itype).execute()
    except HttpError as e:
        print(f"  (deleteall {itype}: {e.status_code})")
    for p in paths:
        try:
            res = edits.images().upload(
                packageName=PKG, editId=eid, language=LANG, imageType=itype,
                media_body=MediaFileUpload(p, mimetype="image/png")).execute()
            print(f"  {itype} <- {os.path.basename(p)} OK  sha1={res['image']['sha1'][:12]}")
        except HttpError as e:
            print(f"  {itype} <- {os.path.basename(p)} FAILED {e.status_code}: {e.reason}")

print("\nskip validate")

try:
    edits.commit(packageName=PKG, editId=eid).execute()
    print("COMMIT OK")
except HttpError as e:
    print("COMMIT FAILED:", e.status_code, e.reason); sys.exit(1)
