class Employee {
  final String id;
  final String name;
  final String phone;
  final String designation;
  final String department;
  final double monthlySalary;
  final String salaryType; // monthly, daily, hourly
  final double dailyWage;
  final String? faceImagePath;
  final String joiningDate;
  final String? address;
  final String? employeeCode;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.designation,
    required this.department,
    required this.monthlySalary,
    this.salaryType = 'monthly',
    this.dailyWage = 0,
    this.faceImagePath,
    required this.joiningDate,
    this.address,
    this.employeeCode,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'designation': designation,
      'department': department,
      'monthlySalary': monthlySalary,
      'salaryType': salaryType,
      'dailyWage': dailyWage,
      'faceImagePath': faceImagePath,
      'joiningDate': joiningDate,
      'address': address,
      'employeeCode': employeeCode,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      designation: map['designation'],
      department: map['department'],
      monthlySalary: map['monthlySalary'].toDouble(),
      salaryType: map['salaryType'] ?? 'monthly',
      dailyWage: (map['dailyWage'] ?? 0).toDouble(),
      faceImagePath: map['faceImagePath'],
      joiningDate: map['joiningDate'],
      address: map['address'],
      employeeCode: map['employeeCode'],
      isActive: (map['isActive'] ?? 1) == 1,
    );
  }

  Employee copyWith({
    String? name,
    String? phone,
    String? designation,
    String? department,
    double? monthlySalary,
    String? salaryType,
    double? dailyWage,
    String? faceImagePath,
    String? address,
    bool? isActive,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      salaryType: salaryType ?? this.salaryType,
      dailyWage: dailyWage ?? this.dailyWage,
      faceImagePath: faceImagePath ?? this.faceImagePath,
      joiningDate: joiningDate,
      address: address ?? this.address,
      employeeCode: employeeCode,
      isActive: isActive ?? this.isActive,
    );
  }
}
