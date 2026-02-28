class ExpenseModel {
  final int     id;
  final String  expenseDate;
  final double  amount;
  final String  category;
  final String  description;
  final String? receiptUrl;
  final String  status; // pending | approved | rejected
  final String? rejectionReason;
  final String? approvedAt;
  final String? employeeName;
  final String? employeeNumber;
  final String? departmentName;
  final String? approvedByName;
  final String  createdAt;

  const ExpenseModel({
    required this.id,
    required this.expenseDate,
    required this.amount,
    required this.category,
    required this.description,
    this.receiptUrl,
    required this.status,
    this.rejectionReason,
    this.approvedAt,
    this.employeeName,
    this.employeeNumber,
    this.departmentName,
    this.approvedByName,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final emp     = json['employee']    as Map<String, dynamic>?;
    final user    = emp?['user']        as Map<String, dynamic>?;
    final dept    = emp?['department']  as Map<String, dynamic>?;
    final appBy   = json['approved_by'] as Map<String, dynamic>?;

    return ExpenseModel(
      id:               json['id'] as int,
      expenseDate:      json['expense_date'] as String,
      amount:           (json['amount'] as num).toDouble(),
      category:         json['category'] as String,
      description:      json['description'] as String,
      receiptUrl:       json['receipt_url'] as String?,
      status:           json['status'] as String,
      rejectionReason:  json['rejection_reason'] as String?,
      approvedAt:       json['approved_at'] as String?,
      employeeName:     user?['name']           as String?,
      employeeNumber:   emp?['employee_number'] as String?,
      departmentName:   dept?['name']           as String?,
      approvedByName:   appBy?['name']          as String?,
      createdAt:        json['created_at'] as String? ?? '',
    );
  }
}
