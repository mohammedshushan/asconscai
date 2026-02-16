class ModuleModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final int order;

  ModuleModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.order,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] ?? 0,
      nameAr: (json['nam_a'] as String?)?.trim() ?? 'Unknown',  // ✅ nam_a بدل nama_a
      nameEn: (json['name_e'] as String?)?.trim() ?? 'Unknown', // ✅ name_e بدل nama_e
      order: json['ord'] ?? 0,
    );
  }
}