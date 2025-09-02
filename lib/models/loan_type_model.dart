// مسار الملف: lib/models/loan_type_model.dart
class LoanType {
final int loanTypeCode;
final String nameA;
final String? nameE;

LoanType({
required this.loanTypeCode,
required this.nameA,
this.nameE,
});

factory LoanType.fromJson(Map<String, dynamic> json) {
return LoanType(
loanTypeCode: json['loan_type_code'] ?? 0,
nameA: json['name_a'] ?? 'غير معروف',
nameE: json['name_e'],
);
}
}

