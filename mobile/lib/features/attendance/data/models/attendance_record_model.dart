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
        id: _toInt(json['id']),
        date: (json['date'] ?? '').toString(),
        checkIn: json['check_in']?.toString(),
        checkOut: json['check_out']?.toString(),
        status: (json['status'] ?? '').toString(),
        workHours: _toDoubleNullable(json['work_hours']),
        notes: json['notes']?.toString(),
      );

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
