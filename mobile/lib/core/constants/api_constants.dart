class ApiConstants {
  ApiConstants._();

  // Base URL
  // DEV  (emulator)  : http://10.0.2.2/api/v1
  // DEV  (real device): http://<your-machine-ip>/api/v1
  // PROD             : https://hrm.kreasikaryaarjuna.co.id/api/v1
  static const String baseUrl = 'https://hrm.kreasikaryaarjuna.co.id/api/v1';

  // Auth
  static const String login   = '/auth/login';
  static const String logout  = '/auth/logout';
  static const String me      = '/auth/me';
  static const String profile = '/auth/profile';

  // Attendance
  static const String attendanceCheckIn  = '/attendance/check-in';
  static const String attendanceCheckOut = '/attendance/check-out';
  static const String attendanceToday    = '/attendance/today';
  static const String attendanceMy       = '/attendance/my';
  static const String attendance         = '/attendance';

  // Leave
  static const String leaveTypes = '/leave-types';
  static const String leaveMy    = '/leave/my';
  static const String leaveQuota = '/leave/quota';
  static const String leave      = '/leave';

  // Overtime
  static const String overtimeMy = '/overtime/my';
  static const String overtime    = '/overtime';

  // Holiday
  static const String holidays = '/holidays';

  // Notifications
  static const String notifications       = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';

  // Face recognition
  static const String faceAttendanceImage = '/face/attendance-image';
  static const String faceMe              = '/face/me';
  static const String faceSelfEnroll      = '/face/self-enroll-image';

  // Payroll (staff)
  static const String payrollMy = '/payroll/my';

  // Tasks & Projects
  static const String projects = '/projects';
  static const String tasks    = '/tasks';

  // Reports
  static const String reportsOverview    = '/reports/overview';
  static const String reportsAttendance  = '/reports/attendance';
  static const String reportsLeave       = '/reports/leave';
  static const String reportsPayroll     = '/reports/payroll';
  static const String reportsOvertime    = '/reports/overtime';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
