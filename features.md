| Feature                                         | Competitor Coverage | Web Status | Mobile Status                  | Priority | Notes |
| ----------------------------------------------- | ------------------- | ---------- | ------------------------------ | -------- | ----- |
| Role-based Auth & Dashboard                     | High                | Done       | Done                           | -        | - |
| Attendance Basic (check-in/out, today, history) | High                | Done       | Done                           | -        | - |
| Leave Management                                | High                | Done       | Done                           | -        | - |
| Overtime Management                             | Medium-High         | Done       | Done                           | -        | - |
| Payslip (employee view)                         | Medium-High         | Done       | Done                           | -        | - |
| Holidays                                        | Medium              | Done       | Done                           | -        | - |
| Notifications (in-app)                          | Medium              | Done       | Done                           | -        | Bell dropdown + /notifications page (filter All/Leave/Overtime/General) |
| Reports (attendance, leave, payroll + CSV)      | High                | Done       | Done                           | -        | Admin/HR: 4 tab (Attendance, Leave, Payroll, Overtime) + filter year/month |
| Face Recognition Attendance                     | Medium-High         | Done       | Done                           | -        | Admin enroll + staff check-in/out |
| Face Self-Enrollment                            | Medium              | -          | Done                           | -        | Staff daftar wajah sendiri via mobile |
| Task & Project Management                       | Medium-High         | Done       | Done                           | -        | Admin/HR CRUD; staff view+checklist |
| Admin delete face data                          | Medium              | Done       | -                              | -        | Tombol delete per baris di /admin/face + confirm dialog |
| Liveness / Anti-spoof                           | Medium              | -          | Done                           | -        | Blink detection (MLKit classification) + head pose gate; backend enforce liveness_verified |
| Account Activation                              | Medium              | Done       | -                              | -        | Karyawan baru default nonaktif; admin aktifkan via tombol Power di tabel; login blocked jika nonaktif |
| Check-in Method Policy                          | Medium              | Done       | Done                           | -        | Admin setting: Any / Face Only / Manual Only; mobile tombol tampil/sembunyi sesuai policy; backend enforce |
| Face Descriptor Encryption (at-rest)           | Medium              | -          | -                              | -        | AES-256-CBC via Laravel encrypted:array cast; idempotent data migration |
| Face Audit Log                                  | Medium              | -          | -                              | -        | Setiap event face (enroll/check-in/no_match/delete) dicatat di audit_logs |
| APK Versioned Download                          | Low                 | Done       | -                              | -        | Halaman login tampil versi+tanggal APK; download filename = facehrm-v1.0.0-b71.apk |
| GPS Attendance + Geofencing                     | High                | Done       | Done                           | -        | Lokasi dicatat di setiap check-in; geofence radius via Settings |
| Anti-fake GPS detection                         | Medium-High         | -          | Done                           | -        | Deteksi isMocked (Android), backend reject jika mock=true |
| Offline attendance + auto sync                  | Medium              | -          | Done                           | -        | Queue di shared_prefs, sync otomatis saat online, anti-duplikasi via 422 |
| Dashboard Admin Mobile (full)                   | High                | Done       | Done                           | -        | Stats grid, Leave/Overtime/Attendance tiles, notification bell |
| Dashboard HR Mobile (full)                      | High                | Done       | Done                           | -        | Stats grid, Leave/Overtime/Attendance tiles, notification bell |
| Shift / Schedule / Break advanced setup         | Medium              | Gap        | Gap                            | P2       | - |
| QR Attendance                                   | Medium              | Gap        | Gap                            | P2       | - |
| Expense / Accounts                              | Medium              | Gap        | Gap                            | P2       | - |
| Communication Suite (meeting/conference)        | Medium              | Gap        | Gap                            | P2       | - |
| Multi-branch / multi-company                    | Medium              | Gap        | Gap                            | P2       | - |
| Push Notifications (FCM)                        | Medium              | Gap        | Gap                            | P2       | In-app notif sudah ada, push belum |
| Profile page mobile                             | Medium              | Done       | Done                           | -        | All roles — view info, edit name/phone, change password |
