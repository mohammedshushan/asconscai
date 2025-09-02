// مسار الملف: lib/models/user_model.dart

class UserModel {
  final int usersCode;
  final String password;
  final String empName;
  final String? empNameE; // قد تكون القيمة null
  final String? jobDesc;
  final String? jobDescE;
  final String gender;
  final int compEmpCode;

  UserModel({
    required this.usersCode,
    required this.password,
    required this.empName,
    this.empNameE,
    this.jobDesc,
    this.jobDescE,
    required this.gender,
    required this.compEmpCode,
  });

  // دالة لإنشاء كائن UserModel من JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      usersCode: json['users_code'],
      password: json['password'],
      empName: json['emp_name'],
      empNameE: json['emp_name_e'],
      jobDesc: json['job_desc'],
      jobDescE: json['job_desc_e'],
      gender: json['gender'],
      compEmpCode: json['comp_emp_code'],
    );
  }

  // دالة لتحويل الكائن إلى JSON (مفيدة لحفظ البيانات)
  Map<String, dynamic> toJson() {
    return {
      'users_code': usersCode,
      'password': password,
      'emp_name': empName,
      'emp_name_e': empNameE,
      'job_desc': jobDesc,
      'job_desc_e': jobDescE,
      'gender': gender,
      'comp_emp_code': compEmpCode,
    };
  }
}


