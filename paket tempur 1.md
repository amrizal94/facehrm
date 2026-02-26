Konteks:
Project: FaceHRM
Path: C:\Users\KK\OneDrive\Documents\Project\FaceHRM
Struktur: backend, web, mobile, docker, deploy
Tujuan: dalam 60 hari sistem siap demo klien pertama dengan kualitas production-ready minimum (stabil, aman, bisa dipakai), bukan sekadar fitur banyak.

MISI UTAMA:
1) Stabilitas core HR flow (auth → absensi → overtime/leave → payroll/report)
2) Security readiness khusus biometric data
3) Delivery discipline (CI/CD + staging + test minimum)
4) Value demo yang kuat untuk decision-maker HR/Finance

PRIORITAS WAJIB (urut implementasi):
A. Auth + RBAC End-to-End (Kritis)
- Audit semua endpoint backend: wajib auth + role guard.
- Samakan role matrix antara backend/web/mobile.
- Pastikan unauthorized flow konsisten (401/403 jelas).

B. Biometric Security Baseline (Kritis)
- Validasi input face descriptor ketat (shape/size/type).
- Rate-limit endpoint face recognition.
- Enkripsi penyimpanan data biometrik (minimal at-rest untuk descriptor).
- Audit log akses endpoint sensitif (who/when/action).

C. Core Business Flow Integration (Tinggi)
- Integrasi overtime + holiday + leave ke payroll calculation.
- Pastikan perubahan status overtime/leave berpengaruh ke payroll summary.
- Satu sumber kebenaran untuk komponen gaji (hindari hitung dobel di frontend).

D. Delivery Reliability (Tinggi)
- Setup CI/CD minimum:
1) lint
2) build backend/web/mobile (sesuai feasible)
3) test minimum
4) deploy staging
- Buat staging environment pakai Docker yang repeatable.

E. Mobile Absensi Real-World (Tinggi)
- Offline-first check-in/check-out + retry/sync ketika online.
- Cegah duplicate attendance saat sync ulang.

F. Notification & UX Operasional (Sedang)
- Rapikan notifikasi overtime/leave/payroll status.
- Pastikan notification bell/web state sinkron dengan backend.

G. Reporting for Demo (Sedang)
- Export payroll/attendance (PDF/CSV) yang usable untuk HR/Finance.
- Dashboard ringkas KPI (hadir, lembur, cuti, payroll total) untuk demo.

H. Observability & Safety Guard (Kritis)
- Error handling terpusat.
- Logging standar + correlation id sederhana.
- Nonaktifkan stack trace bocor di production mode.

DELIVERABLE TEKNIS:
1) Daftar file yang diubah per layer (backend/web/mobile/deploy).
2) Migration/schema change (jika ada) + alasan.
3) Penyesuaian env config (.env.example) tanpa hardcode secret.
4) Test minimum:
- unit test logic payroll/overtime integration
- integration test auth-protected endpoint
- skenario sync absensi offline→online
5) Dokumen ringkas:
- arsitektur flow final
- endpoint kritis + auth requirement
- cara jalankan lokal + staging

ACCEPTANCE CRITERIA (DoD):
- Endpoint sensitif tidak bisa diakses tanpa role sesuai.
- Face endpoint punya validation + rate limit aktif.
- Overtime/leave terbukti memengaruhi payroll output secara konsisten.
- Pipeline CI/CD ke staging berjalan otomatis.
- Skenario e2e lolos:
user login → absen → ajukan lembur/cuti → approval → payroll/report terupdate.

BATASAN:
- Jangan tambah modul besar baru dulu (mis. shift management kompleks, multi-tenant penuh) sebelum core stabil.
- Jangan over-design microservice; perkuat arsitektur sekarang dulu.
- Fokus pada reliability dan keamanan yang bisa diverifikasi.

Rencana 7 Hari Pertama (eksekusi besok):
Hari 1:
- Audit auth+RBAC seluruh endpoint kritis.
- Checklist endpoint public vs protected.

Hari 2:
- Implement rate limit + input validation face endpoint.
- Tambah audit log akses endpoint sensitif.

Hari 3:
- Integrasi overtime/leave ke payroll engine + test unit perhitungan.

Hari 4:
- Setup CI/CD baseline + staging deploy Docker.

Hari 5:
- Rapikan mobile offline attendance sync (anti duplikasi).

Hari 6:
- Notifikasi status + dashboard summary untuk HR/Finance.

Hari 7:
- Full e2e dry-run internal + dokumentasi demo script klien.

OUTPUT YANG DIMINTA DARI CLAUDE:
- Patch/diff implementasi yang konkret.
- Ringkasan perubahan + alasan teknis/bisnis.

---

## Progress Log

### ✅ Mobile Sprint — Selesai (Feb 2026)

**Face Recognition Sprint (Day 1–9)**
- [x] Setup camera + MLKit face detection + image compress
- [x] Face detection real-time overlay (oval guide, status border)
- [x] Capture pipeline + kompres + POST ke backend
- [x] Check-in & check-out via face recognition
- [x] Error handling: low light, no face, multi-face, timeout
- [x] UX polish: AnimatedSwitcher loading states, success checkmark, haptics
- [x] QA: timing fix, race condition stopImageStream → takePicture

**Overtime, Holiday, Notifications Sprint**
- [x] F (Notification & UX Operasional): Mobile notifications — list, mark read, unread badge
- [x] Mobile Overtime: submit, riwayat, cancel, auto-detect weekend/regular
- [x] Mobile Holiday: list hari libur by year, National/Company badge
- [x] Staff dashboard diupdate: 3 tile baru + notification badge di AppBar
- [x] HR/Admin: Overtime Approvals screen (approve/reject with reason)
- [x] `flutter analyze`: 0 issues

**Status item dari Paket Tempur:**
- F. Notification & UX Operasional → ✅ SELESAI (mobile side)
- C. Core Business Flow (overtime/leave → payroll) → 🔄 Backend integration belum diverifikasi
- A, B, D, E, G, H → belum dikerjakan

---

### ✅ Task & Project Management Sprint — Selesai (Feb 2026)

**Backend**
- [x] Tables: labels, projects, tasks, task_label, task_checklist_items
- [x] RBAC: admin/hr = full CRUD; staff = read own tasks + update status + toggle checklist
- [x] Routes: GET labels/projects/tasks (all auth); POST/PUT/DELETE + checklist (admin|hr only)

**Web (`/admin/projects`, `/staff/tasks`)**
- [x] Project table + kanban view (admin)
- [x] Task list + filter by project/status/label (staff)
- [x] Task detail dialog: status dropdown + checklist with optimistic toggle
- [x] Optimistic checklist toggle (instant UI, revert on error, pendingCount ref pattern)

**Mobile**
- [x] Staff tasks list (project chips + status filter)
- [x] Task detail: status dropdown + checklist toggle

**Bug fixes sesi ini:**
- [x] Duplicate tasks cleanup via psql (POST /tasks returned 500 saat development)
- [x] Attendance stats stale cache: useDeleteAttendance kini invalidate `attendance-today` + `attendance-summary`

---

### ✅ Face Self-Enrollment Sprint — Selesai (Feb 2026)

**Backend**
- [x] `GET /face/me` — cek status enrollment wajah user sendiri
- [x] `POST /face/self-enroll-image` — staff daftar wajah sendiri via foto
- [x] Fix: tambah `employee()` hasOne relationship ke User model
- [x] Fix: `bootstrap/cache/*.php` dihapus dari git (tidak di-commit) — fix CI/CD & production 500 error
- [x] Fix: `composer install --no-dev` wajib dijalankan setelah deploy untuk hapus dev dependency dari autoloader

**Mobile**
- [x] `FaceSelfEnrollScreen` — screen kamera untuk self-enrollment wajah
- [x] `FaceCameraScreen` pre-check: GET /face/me sebelum buka kamera check-in; jika belum enroll → redirect FaceSelfEnrollScreen
- [x] Fix: filter `_filterFacesInOval()` — hanya wajah dalam area oval yang dihitung (reject wajah di luar oval / gambar kaos)
- [x] Fix: `minFaceSize` 0.15 → 0.25 untuk filter deteksi palsu (gambar di baju, orang jauh)
- [x] Fix: 800ms delay setelah enrollment sebelum buka kamera FaceCameraScreen (Android camera release timing)

**Web**
- [x] Tombol "Download APK" di halaman login → `/app/facehrm.apk`
- [x] Nginx location block `/app/` untuk serve APK langsung (bypass Next.js)
- [x] Fix ESLint error: `react-hooks/set-state-in-effect` di checklist-panel.tsx (posisi eslint-disable comment)

**CI/CD**
- [x] CI/Deploy pipeline kini berjalan benar setelah semua fix di atas

---

### ✅ Dashboard Polish + Versioning + Task Notifications Sprint — Selesai (Feb 2026)

**Mobile — Admin & HR Dashboard**
- [x] Notification bell (unread badge) di AppBar admin_dashboard + hr_dashboard
- [x] Admin dashboard: ganti tile Reports yg broken (`onTap: () {}`) → Attendance Records (fungsional)
- [x] HR dashboard: sudah ada Attendance Records tile (confirmed)
- [x] `flutter analyze`: 0 issues

**Mobile — APK Versioning**
- [x] Tambah `package_info_plus ^8.1.3` ke pubspec.yaml
- [x] Login screen: tampilkan versi real dari APK (`v1.0.0 (build N)`) via FutureBuilder + PackageInfo
- [x] Hapus `AppConstants.appVersion` hardcoded (tidak relevan lagi)
- [x] `deploy-apk.sh` + `deploy-apk.ps1`: auto `--build-name` + `--build-number` dari git commit count
- [x] Script tulis `version.txt` ke server setelah upload APK

**Backend — Task Notifications**
- [x] `TaskAssigned` notification: kirim ke staff saat task dibuat/diassign ulang ke mereka
- [x] `TaskStatusChanged` notification: kirim ke staff saat admin cancel task mereka
- [x] `TaskController`: trigger notify di `store()` dan `update()`

**Status item dari Paket Tempur:**
- F. Notification & UX Operasional → ✅ SELESAI (mobile + task notif backend)
- A, B, C, D, E, G, H → belum dikerjakan

---

### ✅ GPS Attendance + Geofencing + Anti-fake GPS Sprint — Selesai (Feb 2026)

**Backend**
- [x] Migration: tambah `latitude`, `longitude`, `location_accuracy`, `is_mock_location` ke `attendance_records`
- [x] `AttendanceRecord`: haversine distance method + fillable/casts baru
- [x] `AttendanceResource`: expose location fields di API response
- [x] `SettingController`: 4 key geofence baru (`geofence_enabled`, `office_latitude`, `office_longitude`, `office_radius`)
- [x] `AttendanceController` (`checkIn`/`checkOut`): terima lokasi, validasi geofence, reject mock GPS
- [x] `FaceDataController` (`faceAttendanceImage`): idem untuk face check-in/out

**Web**
- [x] Settings → Attendance Policy: section Geofence (toggle enable + input lat/lng/radius + link Google Maps)
- [x] `types/setting.ts`: tambah 4 field geofence ke `AttendanceSettings`
- [x] `setting-api.ts`: `updateSettings` accept `boolean | null`

**Mobile**
- [x] `geolocator ^13.0.2` + `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` di AndroidManifest
- [x] `LocationService`: get current position + deteksi `isMocked` (anti-fake GPS Android)
- [x] `AttendanceRemoteDatasource`: kirim lokasi saat manual check-in/check-out
- [x] `FaceRemoteDatasource`: kirim lokasi saat face attendance image
- [x] `FaceCameraScreen`: ambil lokasi sebelum capture, pass ke request
- [x] `flutter analyze`: 0 issues

**Behavior:**
- Geofence disabled (default): lokasi dicatat di DB, tidak divalidasi (backward compatible)
- Geofence enabled + terlalu jauh: `"You are 350m away. Maximum allowed is 200m."`
- Mock/fake GPS terdeteksi: langsung ditolak di backend
- GPS tidak tersedia: lokasi null → jika geofence enabled, backend minta aktifkan GPS

**Status item dari Paket Tempur:**
- B. Biometric Security (anti-fake GPS) → ✅ SEBAGIAN SELESAI
- E. Mobile Absensi Real-World → ✅ SELESAI (offline-first + auto sync — lihat sprint berikutnya)
- A, C, D, G, H → belum dikerjakan

---

### ✅ Offline Attendance + Auto Sync Sprint — Selesai (Feb 2026)

**Mobile**
- [x] `connectivity_plus ^6.0.5` + `shared_preferences ^2.3.0` ditambah ke pubspec
- [x] `ConnectivityService` — `connectivityProvider` (StreamProvider<bool>) + `isOnline()` helper
- [x] `PendingAttendanceAction` model — id, action, timestamp, lat/lng/accuracy/isMocked + toJson/fromJson
- [x] `AttendanceLocalDatasource` — queue di shared_preferences: enqueue/remove/pendingCount
- [x] `AttendanceRecordModel` — tambah `isPending: bool` field + `copyWith(checkOut, isPending)`
- [x] `AttendanceRemoteDatasource` — refactor: terima `LocationResult? location` + `DateTime? clientTimestamp` sebagai parameter (tidak capture GPS internal)
- [x] `AttendanceRepository` — `checkIn()`/`checkOut()` capture GPS fresh; `syncCheckIn(action)`/`syncCheckOut(action)` untuk sync path
- [x] `AttendanceSyncNotifier` — watch connectivity, auto-sync queue on reconnect, 422=already synced
- [x] `TodayAttendanceNotifier` — offline-first: cek `isOnline()`, jika offline enqueue + optimistic update
- [x] `staff_dashboard.dart` — amber banner "Attendance saved offline — will sync when connected"
- [x] Snackbar offline-aware: warna amber + pesan offline jika `isPending=true`
- [x] `flutter analyze`: 0 issues

**Backend**
- [x] `AttendanceController::checkIn()` — terima optional `client_checked_in_at` (date) → pakai jika valid (hari ini, tidak di masa depan)
- [x] `AttendanceController::checkOut()` — terima optional `client_checked_out_at` (date) → pakai jika valid

**Flow:**
- Staff check-in offline → disimpan lokal dengan timestamp asli + lokasi → UI langsung update (optimistic)
- Saat online → auto sync → POST ke backend dengan `client_checked_in_at` → backend simpan dengan waktu asli
- Jika backend 422 (sudah ada) → treat sebagai berhasil sync (anti-duplikasi)
- GPS tidak tersedia saat offline → lokasi null → tetap ter-queue, backend terima tanpa GPS

**Status item dari Paket Tempur:**
- E. Mobile Absensi Real-World → ✅ SELESAI
- A, C, D, G, H → belum dikerjakan

---

### ✅ Reports Mobile UI Sprint — Selesai (Feb 2026)

**Mobile**
- [x] 4 model baru: `AttendanceReportModel`, `LeaveReportModel`, `PayrollReportModel`, `OvertimeReportModel`
- [x] `ReportsRemoteDataSource` — 4 metode baru: getAttendanceReport, getLeaveReport, getPayrollReport, getOvertimeReport
- [x] `ReportsRepository` — wrap 4 metode baru
- [x] 4 `FutureProvider.family` baru di `reports_provider.dart`
- [x] `ReportsScreen` — `DefaultTabController` dengan 4 tab:
  - **Attendance**: year+month filter, summary (employees/working days/avg rate), per-employee card (present/late/absent/leave/hours + % rate)
  - **Leave**: year filter, summary (total approved/pending), per-employee list (approved days, pending, rejected)
  - **Payroll**: year+month filter, summary card (total gross/net/deductions + draft/final/paid count), per-employee row (net salary + status badge)
  - **Overtime**: year+month filter, summary (employees/approved hours/pending), per-employee list (approved hours + pending)
- [x] Route `/hr/reports` → `ReportsScreen`
- [x] Reports tile di admin_dashboard + hr_dashboard
- [x] `flutter analyze`: 0 issues
- [x] `_fmtRupiah()` helper: auto abbreviate (jt/M untuk angka besar)

**Status item dari Paket Tempur:**
- G. Reporting for Demo → ✅ SELESAI (mobile reports 4 tab)
- A, C, D, H → belum dikerjakan