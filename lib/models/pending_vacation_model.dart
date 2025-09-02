class PendingVacationRequest {
  final int empCode;
  final int serialPyv;
  final DateTime trnsDate;
  final int trnsType;
  final DateTime startDate;
  final DateTime endDate;
  final int period;
  final DateTime returnDate;
  final String notes;
  final int prevSer;
  final String authPk1;
  final String authPk2;
  final int lastLevel;
  // سنضيف هذه الحقول لاحقاً عندما تتوفر في الـ API
  final String empName;
  final String empNameE;

  PendingVacationRequest({
    required this.empCode,
    required this.serialPyv,
    required this.trnsDate,
    required this.trnsType,
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.returnDate,
    required this.notes,
    required this.prevSer,
    required this.authPk1,
    required this.authPk2,
    required this.lastLevel,
    this.empName = 'اسم الموظف', // قيمة افتراضية
    this.empNameE = 'Employee Name', // قيمة افتراضية
  });

  factory PendingVacationRequest.fromJson(Map<String, dynamic> json) {
    return PendingVacationRequest(
      empCode: json['emp_code'],
      serialPyv: json['serial_pyv'],
      trnsDate: DateTime.parse(json['trns_date']),
      trnsType: json['trns_type'],
      startDate: DateTime.parse(json['start_dt']),
      endDate: DateTime.parse(json['end_dt']),
      period: json['period'],
      returnDate: DateTime.parse(json['return_date']),
      notes: json['notes'] ?? '',
      prevSer: json['prev_ser'],
      authPk1: json['auth_pk1'],
      authPk2: json['auth_pk2'],
      lastLevel: json['last_level'],
      // TODO: استبدل هذه القيم بالقيم الحقيقية من الـ API عند توفرها
      empName: json['emp_name'],
      empNameE: json['emp_name_e'],
    );
  }
}