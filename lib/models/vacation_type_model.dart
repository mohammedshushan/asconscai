class VacationType {
  final int vcncCode;
  final String vcncDescA;
  final String vcncDescE;

  VacationType({
    required this.vcncCode,
    required this.vcncDescA,
    required this.vcncDescE,
  });

  factory VacationType.fromJson(Map<String, dynamic> json) {
    return VacationType(
      vcncCode: json['vcnc_code'] ?? 0,
      vcncDescA: json['vcnc_desc_a'] ?? 'غير معروف',
      vcncDescE: json['vcnc_desc_e'] ?? 'Unknown',
    );
  }
}