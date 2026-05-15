import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import 'database_helper.dart';

class EmployeeService extends ChangeNotifier {
  List<Employee> _employees = [];
  bool _isLoading = false;

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;

  final _uuid = const Uuid();
  final _db = DatabaseHelper.instance;

  EmployeeService() {
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    _isLoading = true;
    notifyListeners();
    try {
      _employees = await _db.getAllEmployees();
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Employee> addEmployee({
    required String name,
    required String phone,
    required String designation,
    required String department,
    required double monthlySalary,
    String salaryType = 'monthly',
    double dailyWage = 0,
    String? faceImagePath,
    String? address,
  }) async {
    final emp = Employee(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      designation: designation,
      department: department,
      monthlySalary: monthlySalary,
      salaryType: salaryType,
      dailyWage: dailyWage,
      faceImagePath: faceImagePath,
      joiningDate: DateTime.now().toIso8601String().split('T')[0],
      address: address,
      employeeCode: 'EMP${_employees.length + 1001}',
    );
    await _db.insertEmployee(emp);
    _employees.insert(0, emp);
    notifyListeners();
    return emp;
  }

  Future<void> updateEmployee(Employee emp) async {
    await _db.updateEmployee(emp);
    final idx = _employees.indexWhere((e) => e.id == emp.id);
    if (idx != -1) {
      _employees[idx] = emp;
      notifyListeners();
    }
  }

  Future<void> deleteEmployee(String id) async {
    await _db.deleteEmployee(id);
    _employees.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Employee? getEmployee(String id) {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateFaceImage(String employeeId, String imagePath) async {
    final emp = getEmployee(employeeId);
    if (emp != null) {
      final updated = emp.copyWith(faceImagePath: imagePath);
      await updateEmployee(updated);
    }
  }

  List<Employee> searchEmployees(String query) {
    if (query.isEmpty) return _employees;
    final q = query.toLowerCase();
    return _employees.where((e) =>
        e.name.toLowerCase().contains(q) ||
        e.phone.contains(q) ||
        e.designation.toLowerCase().contains(q) ||
        (e.employeeCode?.toLowerCase().contains(q) ?? false)).toList();
  }

  Map<String, int> get departmentStats {
    final map = <String, int>{};
    for (var e in _employees) {
      map[e.department] = (map[e.department] ?? 0) + 1;
    }
    return map;
  }
}
