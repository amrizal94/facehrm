| Feature                                         | Competitor Coverage | Web Status | Mobile Status                  | Priority | Notes |
| ----------------------------------------------- | ------------------- | ---------- | ------------------------------ | -------- | ----- |
| Role-based Auth & Dashboard                     | High                | Done       | Done                           | -        | - |
| Attendance Basic (check-in/out, today, history) | High                | Done       | Done                           | -        | - |
| Leave Management                                | High                | Done       | Done                           | -        | - |
| Overtime Management                             | Medium-High         | Done       | Done                           | -        | - |
| Payslip (employee view)                         | Medium-High         | Done       | Done                           | -        | - |
| Holidays                                        | Medium              | Done       | Done                           | -        | - |
| Notifications (in-app)                          | Medium              | -          | Done                           | -        | Web: tidak ada |
| Reports (attendance, leave, payroll + CSV)      | High                | Done       | Partial (API ada, UI terbatas) | P1       | - |
| Face Recognition Attendance                     | Medium-High         | Done       | Done                           | -        | Admin enroll + staff check-in/out |
| Face Self-Enrollment                            | Medium              | -          | Done                           | -        | Staff daftar wajah sendiri via mobile |
| Task & Project Management                       | Medium-High         | Done       | Done                           | -        | Admin/HR CRUD; staff view+checklist |
| Admin delete face data                          | Medium              | Done       | -                              | -        | Tombol delete per baris di /admin/face + confirm dialog |
| Liveness / Anti-spoof                           | Medium              | -          | Gap                            | P1       | - |
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
| Profile page mobile                             | Medium              | Done       | Gap                            | P2       | Staff belum bisa lihat/edit profil di mobile |
