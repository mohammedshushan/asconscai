class VacationOrder {
  final int serialPyv;
  final int empCode;
  final DateTime trnsDate;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? returnDate;
  final int trnsType;
  final int period;
  final int agreeFlag; // 0: معلق, 1: معتمد, -1: مرفوض
  final String? notes;

  VacationOrder({
    required this.serialPyv,
    required this.empCode,
    required this.trnsDate,
    required this.startDate,
    required this.endDate,
    this.returnDate,
    required this.trnsType,
    required this.period,
    required this.agreeFlag,
    this.notes,
  });

  factory VacationOrder.fromJson(Map<String, dynamic> json) {
    return VacationOrder(
      serialPyv: json['serial_pyv'] ?? 0,
      empCode: json['emp_code'] ?? 0,
      trnsDate: DateTime.tryParse(json['trns_date'] ?? '') ?? DateTime.now(),
      startDate: DateTime.tryParse(json['start_dt'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_dt'] ?? '') ?? DateTime.now(),
      returnDate: DateTime.tryParse(json['return_date'] ?? ''),
      trnsType: json['trns_type'] ?? 0,
      period: json['period'] ?? 0,
      agreeFlag: json['agree_flag'] ?? 0,
      notes: json['notes'],
    );
  }
}
