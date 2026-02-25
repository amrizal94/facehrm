class AppRoutes {
  AppRoutes._();

  static const String splash         = '/';
  static const String login          = '/login';
  static const String dashboard      = '/dashboard';
  static const String adminDashboard = '/dashboard/admin';
  static const String hrDashboard    = '/dashboard/hr';
  static const String staffDashboard = '/dashboard/staff';
  static const String unauthorized   = '/unauthorized';

  // Staff features
  static const String myAttendance = '/staff/attendance';
  static const String myLeaves     = '/staff/leaves';
  static const String applyLeave   = '/staff/leaves/apply';
  static const String myPayslips    = '/staff/payslips';
  static const String payslipDetail = '/staff/payslips/:id';
  static const String myOvertime     = '/staff/overtime';
  static const String submitOvertime = '/staff/overtime/submit';
  static const String holidays       = '/staff/holidays';
  static const String notifications  = '/staff/notifications';

  // HR / Admin
  static const String leaveApprovals       = '/hr/leave-approvals';
  static const String overtimeApprovals    = '/hr/overtime-approvals';
  static const String attendanceRecords    = '/hr/attendance-records';
}
