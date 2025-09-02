

class EmployeeProfileModel {
  final int usersCode;
  final String? password;
  final int empCode;
  final int compEmpCode;
  final String? empName;
  final String? empNameE;
  final int? ntnltyCode;
  final int? qlfyCtgryCode;
  final int? qlfyCode;
  final int? religionType;
  final DateTime? birthDate;
  final String? birthPlace;
  final int? socialStatus;
  final String? currentAddress;
  final String? currentAddressE;
  final int? jobCode;
  final String? jobDesc;
  final String? gender;

  EmployeeProfileModel({
    required this.usersCode,
    this.password,
    required this.empCode,
    required this.compEmpCode,
    this.empName,
    this.empNameE,
    this.ntnltyCode,
    this.qlfyCtgryCode,
    this.qlfyCode,
    this.religionType,
    this.birthDate,
    this.birthPlace,
    this.socialStatus,
    this.currentAddress,
    this.currentAddressE,
    this.jobCode,
    this.jobDesc,
    this.gender,
  });

  factory EmployeeProfileModel.fromJson(Map<String, dynamic> json) {
    return EmployeeProfileModel(
      usersCode: json['users_code'] ?? 0,
      password: json['password'],
      empCode: json['emp_code'] ?? 0,
      compEmpCode: json['comp_emp_code'] ?? 0,
      empName: json['emp_name'],
      empNameE: json['emp_name_e'],
      ntnltyCode: json['ntnlty_code'],
      qlfyCtgryCode: json['qlfy_ctgry_code'],
      qlfyCode: json['qlfy_code'],
      religionType: json['religion_type'],
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'])
          : null,
      birthPlace: json['birth_plc'],
      socialStatus: json['social_status'],
      currentAddress: json['current_address'],
      currentAddressE: json['current_address_e'],
      jobCode: json['job_code'],
      jobDesc: json['job_desc'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users_code': usersCode,
      'password': password,
      'emp_code': empCode,
      'comp_emp_code': compEmpCode,
      'emp_name': empName,
      'emp_name_e': empNameE,
      'ntnlty_code': ntnltyCode,
      'qlfy_ctgry_code': qlfyCtgryCode,
      'qlfy_code': qlfyCode,
      'religion_type': religionType,
      'birth_date': birthDate?.toIso8601String(),
      'birth_plc': birthPlace,
      'social_status': socialStatus,
      'current_address': currentAddress,
      'current_address_e': currentAddressE,
      'job_code': jobCode,
      'job_desc': jobDesc,
      'gender': gender,
    };
  }

  // دوال مساعدة للعرض
  String get displayName => empName ?? empNameE ?? 'غير محدد';

  String get formattedBirthDate {
    if (birthDate == null) return '-';
    return '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}';
  }

  String getSocialStatusText(bool isArabic) {
    switch (socialStatus) {
      case 0:
        return isArabic ? 'أعزب' : 'Single';
      case 1:
        return isArabic ? 'متزوج' : 'Married';
      case 2:
        return isArabic ? 'مطلق' : 'Divorced';
      case 3:
        return isArabic ? 'أرمل' : 'Widowed';
      default:
        return '-';
    }
  }

  String getGenderText(bool isArabic) {
    if (gender == 'M') return isArabic ? 'ذكر' : 'Male';
    if (gender == 'F') return isArabic ? 'أنثى' : 'Female';
    return '-';
  }

  String getReligionText(bool isArabic) {
    switch (religionType) {
      case 1:
        return isArabic ? 'مسلم' : 'Muslim';
      case 2:
        return isArabic ? 'مسيحي' : 'Christian';
      case 3:
        return isArabic ? 'يهودي' : 'Jewish';
      default:
        return '-';
    }
  }

  @override
  String toString() {
    return 'EmployeeProfileModel{usersCode: $usersCode, empName: $empName, jobDesc: $jobDesc}';
  }
}