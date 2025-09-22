class PendingLoanRequest {
  final int empCode;
  final String empName;
  final String empNameE;
  final int reqSerial;
  final int compEmpCode;
  final int loanType;
  final int loanNos;
  final double loanValuePys;
  final double loanInstlPys;
  final DateTime loanStartDdctDt;
  final DateTime reqLoanDate;
  final DateTime loanStartDate;
  final String? notes;
  final int fileSerial;
  final int prevSer;
  final int usersCode;
  final String authPk1;
  final String authPk2;
  final int? trnsFlag;
  final int? trnsStatus;
  final dynamic trnsDateAuth;
  final int lastLevel;

  PendingLoanRequest({
    required this.empCode,
    required this.empName,
    required this.empNameE,
    required this.reqSerial,
    required this.compEmpCode,
    required this.loanType,
    required this.loanNos,
    required this.loanValuePys,
    required this.loanInstlPys,
    required this.loanStartDdctDt,
    required this.reqLoanDate,
    required this.loanStartDate,
    this.notes,
    required this.fileSerial,
    required this.prevSer,
    required this.usersCode,
    required this.authPk1,
    required this.authPk2,
    this.trnsFlag,
    this.trnsStatus,
    this.trnsDateAuth,
    required this.lastLevel,
  });

  factory PendingLoanRequest.fromJson(Map<String, dynamic> json) {
    return PendingLoanRequest(
      empCode: json['emp_code'],
      empName: json['emp_name'],
      empNameE: json['emp_name_e'],
      reqSerial: json['req_serial'],
      compEmpCode: json['comp_emp_code'],
      loanType: json['loan_type'],
      loanNos: json['loan_nos'],
      loanValuePys: (json['loan_value_pys'] as num).toDouble(),
      loanInstlPys: (json['loan_instl_pys'] as num).toDouble(),
      loanStartDdctDt: DateTime.parse(json['loan_start_ddct_dt']),
      reqLoanDate: DateTime.parse(json['req_loan_date']),
      loanStartDate: DateTime.parse(json['loan_start_date']),
      notes: json['notes'],
      fileSerial: json['file_serial'],
      prevSer: json['prev_ser'],
      usersCode: json['users_code'],
      authPk1: json['auth_pk1'],
      authPk2: json['auth_pk2'],
      trnsFlag: json['trns_flag'],
      trnsStatus: json['trns_status'],
      trnsDateAuth: json['trns_date_auth'],
      lastLevel: json['last_level'],
    );
  }
}