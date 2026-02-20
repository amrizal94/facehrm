class PayslipModel {
  final int id;
  final int periodYear;
  final int periodMonth;
  final double basicSalary;
  final double allowances;
  final double overtimePay;
  final double grossSalary;
  final double absentDeduction;
  final double taxDeduction;
  final double bpjsDeduction;
  final double otherDeductions;
  final double netSalary;
  final int presentDays;
  final int absentDays;
  final int workingDays;
  final String status;

  const PayslipModel({
    required this.id,
    required this.periodYear,
    required this.periodMonth,
    required this.basicSalary,
    this.allowances = 0,
    this.overtimePay = 0,
    required this.grossSalary,
    this.absentDeduction = 0,
    this.taxDeduction = 0,
    this.bpjsDeduction = 0,
    this.otherDeductions = 0,
    required this.netSalary,
    this.presentDays = 0,
    this.absentDays = 0,
    this.workingDays = 0,
    required this.status,
  });

  factory PayslipModel.fromJson(Map<String, dynamic> json) => PayslipModel(
        id: json['id'] as int,
        periodYear: json['period_year'] as int,
        periodMonth: json['period_month'] as int,
        basicSalary: (json['basic_salary'] as num).toDouble(),
        allowances: (json['allowances'] as num?)?.toDouble() ?? 0,
        overtimePay: (json['overtime_pay'] as num?)?.toDouble() ?? 0,
        grossSalary: (json['gross_salary'] as num).toDouble(),
        absentDeduction: (json['absent_deduction'] as num?)?.toDouble() ?? 0,
        taxDeduction: (json['tax_deduction'] as num?)?.toDouble() ?? 0,
        bpjsDeduction: (json['bpjs_deduction'] as num?)?.toDouble() ?? 0,
        otherDeductions: (json['other_deductions'] as num?)?.toDouble() ?? 0,
        netSalary: (json['net_salary'] as num).toDouble(),
        presentDays: json['present_days'] as int? ?? 0,
        absentDays: json['absent_days'] as int? ?? 0,
        workingDays: json['working_days'] as int? ?? 0,
        status: json['status'] as String,
      );
}
