class AttendanceRecord {
  final String id;
  final String employeeId;
  final String date; // yyyy-MM-dd
  final String? punchInTime;
  final String? punchOutTime;
  final String status; // present, absent, half_day, leave, holiday
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String? faceImagePath;
  final bool faceVerified;
  final String? notes;
  final double overtimeHours;
  final double deduction;

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    this.punchInTime,
    this.punchOutTime,
    required this.status,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.faceImagePath,
    this.faceVerified = false,
    this.notes,
    this.overtimeHours = 0,
    this.deduction = 0,
  });

  Duration get workDuration {
    if (punchInTime == null || punchOutTime == null) return Duration.zero;
    try {
      final inParts = punchInTime!.split(':');
      final outParts = punchOutTime!.split(':');
      final inMinutes = int.parse(inParts[0]) * 60 + int.parse(inParts[1]);
      final outMinutes = int.parse(outParts[0]) * 60 + int.parse(outParts[1]);
      return Duration(minutes: outMinutes - inMinutes);
    } catch (_) {
      return Duration.zero;
    }
  }

  String get workHoursDisplay {
    final d = workDuration;
    if (d == Duration.zero) return '--';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date,
      'punchInTime': punchInTime,
      'punchOutTime': punchOutTime,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'faceImagePath': faceImagePath,
      'faceVerified': faceVerified ? 1 : 0,
      'notes': notes,
      'overtimeHours': overtimeHours,
      'deduction': deduction,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      employeeId: map['employeeId'],
      date: map['date'],
      punchInTime: map['punchInTime'],
      punchOutTime: map['punchOutTime'],
      status: map['status'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationAddress: map['locationAddress'],
      faceImagePath: map['faceImagePath'],
      faceVerified: (map['faceVerified'] ?? 0) == 1,
      notes: map['notes'],
      overtimeHours: (map['overtimeHours'] ?? 0).toDouble(),
      deduction: (map['deduction'] ?? 0).toDouble(),
    );
  }
}

class SalaryRecord {
  final String id;
  final String employeeId;
  final String month; // yyyy-MM
  final int presentDays;
  final int absentDays;
  final int halfDays;
  final double grossSalary;
  final double deductions;
  final double advances;
  final double netSalary;
  final bool isPaid;
  final String? paymentDate;
  final String? paymentMode;

  SalaryRecord({
    required this.id,
    required this.employeeId,
    required this.month,
    required this.presentDays,
    required this.absentDays,
    required this.halfDays,
    required this.grossSalary,
    required this.deductions,
    required this.advances,
    required this.netSalary,
    this.isPaid = false,
    this.paymentDate,
    this.paymentMode,
  });
}
