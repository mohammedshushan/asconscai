class PendingPermissionRequest {
  final int empCode;
  final String empName;
  final String empNameE;
  final int serial;
  final int compEmpCode;
  final DateTime exitDate;
  final DateTime enterDate;
  final int exitReasonCode;
  final String exitReason;
  final DateTime exitTime;
  final DateTime enterTime;
  final String? notes;
  final int fileSerial;
  final int prevSer;
  final int usersCode;
  final String authPk1;
  final String authPk2;
  final int? trnsFlag;
  final int? trnsStatus;
  final dynamic trnsDateAuth; // Can be null
  final int lastLevel;

  PendingPermissionRequest({
    required this.empCode,
    required this.empName,
    required this.empNameE,
    required this.serial,
    required this.compEmpCode,
    required this.exitDate,
    required this.enterDate,
    required this.exitReasonCode,
    required this.exitReason,
    required this.exitTime,
    required this.enterTime,
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

  factory PendingPermissionRequest.fromJson(Map<String, dynamic> json) {
    return PendingPermissionRequest(
      empCode: json['emp_code'],
      empName: json['emp_name'],
      empNameE: json['emp_name_e'],
      serial: json['serial'],
      compEmpCode: json['comp_emp_code'],
      exitDate: DateTime.parse(json['exit_date']),
      enterDate: DateTime.parse(json['enter_date']),
      exitReasonCode: json['exit_reason_code'],
      exitReason: json['exit_reason'],
      exitTime: DateTime.parse(json['exit_time']),
      enterTime: DateTime.parse(json['enter_time']),
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