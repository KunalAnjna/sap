import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import 'database_helper.dart';

class AttendanceService extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Map<String, AttendanceRecord> _todayRecords = {};
  List<AttendanceRecord> _selectedDateRecords = [];
  bool _isLoading = false;

  Map<String, AttendanceRecord> get todayRecords => _todayRecords;
  List<AttendanceRecord> get selectedDateRecords => _selectedDateRecords;
  bool get isLoading => _isLoading;

  String get today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  AttendanceService() {
    loadTodayAttendance();
  }

  Future<void> loadTodayAttendance() async {
    _isLoading = true;
    notifyListeners();
    try {
      final records = await _db.getAttendanceByDate(today);
      _todayRecords = {for (var r in records) r.employeeId: r};
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<AttendanceRecord?> getTodayRecord(String employeeId) async {
    return await _db.getTodayAttendance(employeeId, today);
  }

  Future<AttendanceRecord> markAttendance({
    required String employeeId,
    required String status,
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? faceImagePath,
    bool faceVerified = false,
    String? notes,
  }) async {
    final existing = _todayRecords[employeeId];
    final now = DateFormat('HH:mm').format(DateTime.now());

    if (existing != null) {
      // Punch out
      final updated = AttendanceRecord(
        id: existing.id,
        employeeId: employeeId,
        date: today,
        punchInTime: existing.punchInTime,
        punchOutTime: now,
        status: status,
        latitude: latitude ?? existing.latitude,
        longitude: longitude ?? existing.longitude,
        locationAddress: locationAddress ?? existing.locationAddress,
        faceImagePath: faceImagePath ?? existing.faceImagePath,
        faceVerified: faceVerified || existing.faceVerified,
        notes: notes,
        overtimeHours: existing.overtimeHours,
        deduction: existing.deduction,
      );
      await _db.updateAttendance(updated);
      _todayRecords[employeeId] = updated;
      notifyListeners();
      return updated;
    } else {
      // Punch in
      final record = AttendanceRecord(
        id: _uuid.v4(),
        employeeId: employeeId,
        date: today,
        punchInTime: now,
        status: status,
        latitude: latitude,
        longitude: longitude,
        locationAddress: locationAddress,
        faceImagePath: faceImagePath,
        faceVerified: faceVerified,
        notes: notes,
      );
      await _db.insertAttendance(record);
      _todayRecords[employeeId] = record;
      notifyListeners();
      return record;
    }
  }

  Future<void> manualMarkAttendance({
    required String employeeId,
    required String date,
    required String status,
    String? notes,
  }) async {
    final existing = await _db.getTodayAttendance(employeeId, date);
    if (existing != null) {
      final updated = AttendanceRecord(
        id: existing.id,
        employeeId: employeeId,
        date: date,
        punchInTime: existing.punchInTime,
        punchOutTime: existing.punchOutTime,
        status: status,
        latitude: existing.latitude,
        longitude: existing.longitude,
        locationAddress: existing.locationAddress,
        faceImagePath: existing.faceImagePath,
        faceVerified: existing.faceVerified,
        notes: notes ?? existing.notes,
      );
      await _db.updateAttendance(updated);
    } else {
      final record = AttendanceRecord(
        id: _uuid.v4(),
        employeeId: employeeId,
        date: date,
        status: status,
        notes: notes,
      );
      await _db.insertAttendance(record);
    }
    if (date == today) await loadTodayAttendance();
    notifyListeners();
  }

  Future<List<AttendanceRecord>> getEmployeeAttendance(
      String employeeId, String month) async {
    return await _db.getEmployeeAttendance(employeeId, month);
  }

  Future<Map<String, int>> getMonthlyStats(
      String employeeId, String month) async {
    return await _db.getMonthlyStats(employeeId, month);
  }

  Future<double> calculateMonthlySalary(
      String employeeId, double monthlySalary, String month) async {
    final stats = await getMonthlyStats(employeeId, month);
    const workingDays = 26;
    final perDay = monthlySalary / workingDays;
    final present = stats['present'] ?? 0;
    final halfDay = stats['half_day'] ?? 0;
    final earned = (present * perDay) + (halfDay * perDay * 0.5);
    return earned;
  }

  Future<void> loadDateRecords(String date) async {
    _selectedDateRecords = await _db.getAttendanceByDate(date);
    notifyListeners();
  }

  Map<String, int> get todayStats {
    int present = 0, absent = 0, halfDay = 0;
    for (var r in _todayRecords.values) {
      switch (r.status) {
        case 'present': present++; break;
        case 'absent': absent++; break;
        case 'half_day': halfDay++; break;
      }
    }
    return {'present': present, 'absent': absent, 'half_day': halfDay};
  }
}
