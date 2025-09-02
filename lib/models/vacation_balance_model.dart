/// هذا الكلاس يمثل كائن رصيد الإجازة
class VacationBalance {
  final int empCode;
  final String vcncDescA; // اسم الإجازة بالعربي
  final String vcncDescE; // اسم الإجازة بالإنجليزي
  final int vcncCode;
  final int total; // الرصيد المستخدم (الذي حصل عليه)
  final int remainBal; // الرصيد المتبقي

  VacationBalance({
    required this.empCode,
    required this.vcncDescA,
    required this.vcncDescE,
    required this.vcncCode,
    required this.total,
    required this.remainBal,
  });

  /// دالة getter لحساب الرصيد الإجمالي (المستخدم + المتبقي)
  int get fullBalance => total + remainBal;

  /// Factory constructor لإنشاء نسخة من هذا الكائن من بيانات JSON
  factory VacationBalance.fromJson(Map<String, dynamic> json) {
    return VacationBalance(
      empCode: json['emp_code'] ?? 0,
      vcncDescA: json['vcnc_desc_a'] ?? 'غير متوفر',
      vcncDescE: json['vcnc_desc_e'] ?? 'Not Available',
      vcncCode: json['vcnc_code'] ?? 0,
      total: json['total'] ?? 0,
      remainBal: json['remain_bal'] ?? 0,
    );
  }
}