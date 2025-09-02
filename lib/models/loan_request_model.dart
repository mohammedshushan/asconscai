// ----------------------------------------------------

// مسار الملف: lib/models/loan_request_model.dart
class LoanRequest {
  final int empCode;
  final int reqSerial;
  final int loanType;
  final DateTime reqLoanDate;
  final DateTime loanStartDate;
  final double loanValuePys;
  final double loanInstlPys;
  final int loanNos;
  final int authFlag; // 0: معلق, 1: معتمد, -1: مرفوض
  final String? notes;

  LoanRequest({
    required this.empCode,
    required this.reqSerial,
    required this.loanType,
    required this.reqLoanDate,
    required this.loanStartDate,
    required this.loanValuePys,
    required this.loanInstlPys,
    required this.loanNos,
    required this.authFlag,
    this.notes,
  });

  factory LoanRequest.fromJson(Map<String, dynamic> json) {
    return LoanRequest(
      empCode: json['emp_code'] ?? 0,
      reqSerial: json['req_serial'] ?? 0,
      loanType: json['loan_type'] ?? 0,
      reqLoanDate: DateTime.tryParse(json['req_loan_date'] ?? '') ?? DateTime.now(),
      loanStartDate: DateTime.tryParse(json['loan_start_date'] ?? '') ?? DateTime.now(),
      loanValuePys: (json['loan_value_pys'] as num?)?.toDouble() ?? 0.0,
      loanInstlPys: (json['loan_instl_pys'] as num?)?.toDouble() ?? 0.0,
      loanNos: json['loan_nos'] ?? 0,
      authFlag: json['auth_flag'] ?? 0,
      notes: json['notes'],
    );
  }
}
