import 'dart:convert';

class PermissionRequest {
  final int empCode;
  final DateTime exitDate;
  final DateTime enterDate;
  final DateTime exitTime;
  final DateTime enterTime;
  final int reasonCode;
  final int acceptFlag;
  final String? notes;
  final String? exitReason;
  final int serial;

  PermissionRequest({
    required this.empCode,
    required this.exitDate,
    required this.enterDate,
    required this.exitTime,
    required this.enterTime,
    required this.reasonCode,
    required this.acceptFlag,
    this.notes,
    this.exitReason,
    required this.serial,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      empCode: json['emp_code'] ?? 0,
      exitDate: json['exit_date'] != null ? DateTime.parse(json['exit_date']) : DateTime.now(),
      enterDate: json['enter_date'] != null ? DateTime.parse(json['enter_date']) : DateTime.now(),
      exitTime: json['exit_time'] != null ? DateTime.parse(json['exit_time']) : DateTime.now(),
      enterTime: json['enter_time'] != null ? DateTime.parse(json['enter_time']) : DateTime.now(),
      reasonCode: json['exit_reason_code'] ?? 0,
      acceptFlag: json['accept_flag'] ?? 0,
      notes: json['notes'],
      exitReason: json['exit_reason'],
      serial: json['serial'] ?? 0,
    );
  }
}

List<PermissionRequest> parsePermissionRequests(String responseBody) {
  final parsed = json.decode(responseBody);
  if (parsed['items'] == null) return [];
  return (parsed['items'] as List)
      .map<PermissionRequest>((json) => PermissionRequest.fromJson(json))
      .toList();
}