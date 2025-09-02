// مسار الملف: lib/models/module_model.dart

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
      id: json['id'],
      nameAr: json['nama_a'],
      // إزالة المسافات الزائدة والأسطر الجديدة
      nameEn: (json['nama_e'] as String?)?.trim() ?? '',
      order: json['ord'],
    );
  }
}