# Staff Attendance Pro 🏢
**Face Attendance + GPS Distance Tracking + Salary Management**

---

## ⚡ Codemagic Se Deploy Karo (Seedha)

### Step 1 — GitHub pe upload karo
1. GitHub.com pe naya repo banao
2. Ye saari files upload karo (ya git push karo)

### Step 2 — Codemagic connect karo
1. codemagic.io pe jaao → Sign up with GitHub
2. "Add application" → apna repo chunao
3. `codemagic.yaml` automatically detect hoga
4. **Android Workflow** ya **iOS Workflow** select karo → Start build

### Step 3 — Pehle ye karo (ZARURI)
`android/app/src/main/AndroidManifest.xml` mein:
```xml
android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"
```
→ Apni key se replace karo (console.cloud.google.com se free mein milti hai)

`web/index.html` mein bhi same key daalo.

---

## 🔑 Kya Milega Build Ke Baad
| Platform | File | Kahan milegi |
|----------|------|-------------|
| Android APK | `app-release.apk` | Seedha install kar sakte ho |
| Android AAB | `app-release.aab` | Play Store pe upload karo |
| iOS IPA | `*.ipa` | App Store pe upload karo |
| Web | `build/web/` | Kisi bhi server pe host karo |

---

## 📁 Project Structure
```
staff_attendance_pro/
├── codemagic.yaml          ← Codemagic build config
├── pubspec.yaml            ← Dependencies
├── android/                ← Android native files
├── ios/                    ← iOS native files (Info.plist)
├── web/                    ← Web files (index.html)
├── test/                   ← Tests
└── lib/
    ├── main.dart
    ├── models/
    │   ├── employee.dart
    │   └── attendance_record.dart
    ├── services/
    │   ├── database_helper.dart
    │   ├── employee_service.dart
    │   ├── attendance_service.dart
    │   └── location_service.dart
    └── screens/
        ├── splash_screen.dart
        ├── main_navigation.dart
        ├── home_screen.dart
        ├── employees_screen.dart
        ├── add_employee_screen.dart
        ├── employee_detail_screen.dart
        ├── face_attendance_screen.dart    ← Face camera
        ├── location_tracking_screen.dart  ← GPS + distance
        ├── attendance_screen.dart
        ├── salary_screen.dart
        └── reports_screen.dart
```

---

## ✅ Features
- 😊 Face Attendance — camera se chehra detect
- 📍 GPS Tracking — start→end distance, time, speed, map route
- 👥 Staff Management — add/edit/delete
- 💰 Salary Calculator — auto attendance se
- 📊 Reports
- 📴 Offline SQLite database
