class AttendanceRecordModel {
  final int id;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final double? workHours;
  final String? notes;

  const AttendanceRecordModel({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.workHours,
    this.notes,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordModel(
        id: json['id'] as int,
        date: json['date'] as String,
        checkIn: json['check_in'] as String?,
        checkOut: json['check_out'] as String?,
        status: json['status'] as String,
        workHours: (json['work_hours'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}
