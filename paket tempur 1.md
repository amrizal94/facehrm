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