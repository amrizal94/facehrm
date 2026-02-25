# FaceHRM Mobile

Flutter mobile app untuk sistem HR management FaceHRM.

## Stack
- Flutter (Dart)
- Riverpod (`flutter_riverpod`) — state management
- GoRouter — navigation + route guard
- Dio — HTTP client
- google_mlkit_face_detection — face detection real-time
- camera — kamera preview + capture

## Fitur
| Modul | Role | Keterangan |
|-------|------|------------|
| Auth | Semua | Login, logout, session restore |
| Dashboard | Staff/HR/Admin | Clock live, quick menu, notification badge |
| Attendance | Staff | Face check-in/out (MLKit), manual, riwayat |
| Leave | Staff | Apply cuti, riwayat, cancel pending |
| Overtime | Staff | Submit lembur, riwayat, cancel pending |
| Payslip | Staff | Daftar payslip + detail |
| Holiday | Staff | Kalender hari libur nasional & perusahaan |
| Notifications | Staff | Inbox notif, mark read, mark all read |
| Leave Approvals | HR/Admin | Approve/reject cuti |
| Overtime Approvals | HR/Admin | Approve/reject lembur |
| Attendance Records | HR/Admin | Rekap absensi karyawan |

## Struktur Folder
```
lib/
  core/
    constants/    # ApiConstants, AppConstants
    network/      # DioClient, ApiException
    router/       # AppRouter (GoRouter), AppRoutes
    theme/
  features/
    auth/
    dashboard/
    attendance/
    face/         # MLKit face camera screen
    leave/
    overtime/
    holiday/
    notifications/
    payslip/
```

## Setup
```bash
flutter pub get
flutter run
```

> Pastikan device/emulator sudah running. Untuk Android emulator gunakan base URL `http://10.0.2.2/api/v1`.

## Environment
Base URL ada di `lib/core/constants/api_constants.dart`:
- **Production**: `https://hrm.kreasikaryaarjuna.co.id/api/v1`
- **Dev (emulator)**: `http://10.0.2.2/api/v1`
- **Dev (device fisik)**: `http://<your-machine-ip>/api/v1`

## Build Android
```bash
flutter build apk --release
```

Jika build gagal karena java.exe lock di Windows:
```bash
taskkill //F //IM java.exe
rm -rf build/
flutter build apk --release
```
