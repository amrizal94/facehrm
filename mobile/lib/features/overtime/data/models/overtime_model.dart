class OvertimeModel {
  final int id;
  final String date;
  final double overtimeHours;
  final String overtimeType;
  final String reason;
  final String status;
  final String? rejectionReason;
  final String? approvedByName;
  final String? createdAt;

  const OvertimeModel({
    required this.id,
    required this.date,
    required this.overtimeHours,
    required this.overtimeType,
    required this.reason,
    required this.status,
    this.rejectionReason,
    this.approvedByName,
    this.createdAt,
  });

  factory OvertimeModel.fromJson(Map<String, dynamic> json) => OvertimeModel(
        id: json['id'] as int,
        date: json['date'] as String,
        overtimeHours: (json['overtime_hours'] as num).toDouble(),
        overtimeType: json['overtime_type'] as String,
        reason: json['reason'] as String,
        status: json['status'] as String,
        rejectionReason: json['rejection_reason'] as String?,
        approvedByName: json['approved_by_name'] as String?,
        createdAt: json['created_at'] as String?,
      );
}
