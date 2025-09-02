import 'dart:convert';

class PermissionType {
  final int code;
  final String reasonAr;
  final String? reasonEn;

  PermissionType({
    required this.code,
    required this.reasonAr,
    this.reasonEn,
  });

  factory PermissionType.fromJson(Map<String, dynamic> json) {
    return PermissionType(
      code: json['code'] ?? 0,
      reasonAr: json['reason_ar'] ?? 'غير معروف',
      reasonEn: json['reason_en'],
    );
  }

  // Helper to get the localized name
  String getLocalizedName(bool isRtl) {
    if (isRtl) {
      return reasonAr;
    }
    return reasonEn ?? reasonAr;
  }
}

List<PermissionType> parsePermissionTypes(String responseBody) {
  final parsed = json.decode(responseBody);
  if (parsed['items'] == null) return [];
  return (parsed['items'] as List)
      .map<PermissionType>((json) => PermissionType.fromJson(json))
      .toList();
}