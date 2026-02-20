class LeaveRequestModel {
  final int id;
  final int leaveTypeId;
  final String leaveTypeName;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String reason;
  final String status;
  final String? rejectReason;
  final String? createdAt;

  const LeaveRequestModel({
    required this.id,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.rejectReason,
    this.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) => LeaveRequestModel(
        id: json['id'] as int,
        leaveTypeId: json['leave_type_id'] as int,
        leaveTypeName: json['leave_type_name'] as String? ?? '',
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        totalDays: json['total_days'] as int,
        reason: json['reason'] as String,
        status: json['status'] as String,
        rejectReason: json['reject_reason'] as String?,
        createdAt: json['created_at'] as String?,
      );
}
