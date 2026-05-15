import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'staff_attendance.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        designation TEXT NOT NULL,
        department TEXT NOT NULL,
        monthlySalary REAL NOT NULL,
        salaryType TEXT DEFAULT 'monthly',
        dailyWage REAL DEFAULT 0,
        faceImagePath TEXT,
        joiningDate TEXT NOT NULL,
        address TEXT,
        employeeCode TEXT,
        isActive INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        date TEXT NOT NULL,
        punchInTime TEXT,
        punchOutTime TEXT,
        status TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        locationAddress TEXT,
        faceImagePath TEXT,
        faceVerified INTEGER DEFAULT 0,
        notes TEXT,
        overtimeHours REAL DEFAULT 0,
        deduction REAL DEFAULT 0,
        FOREIGN KEY (employeeId) REFERENCES employees (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE advances (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        reason TEXT,
        isPaid INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE salary_records (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        month TEXT NOT NULL,
        presentDays INTEGER DEFAULT 0,
        absentDays INTEGER DEFAULT 0,
        halfDays INTEGER DEFAULT 0,
        grossSalary REAL DEFAULT 0,
        deductions REAL DEFAULT 0,
        advances REAL DEFAULT 0,
        netSalary REAL DEFAULT 0,
        isPaid INTEGER DEFAULT 0,
        paymentDate TEXT,
        paymentMode TEXT
      )
    ''');
  }

  // ============ EMPLOYEE CRUD ============
  Future<void> insertEmployee(Employee emp) async {
    final db = await database;
    await db.insert('employees', emp.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final maps = await db.query('employees', where: 'isActive = 1');
    return maps.map((m) => Employee.fromMap(m)).toList();
  }

  Future<Employee?> getEmployee(String id) async {
    final db = await database;
    final maps = await db.query('employees', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  Future<void> updateEmployee(Employee emp) async {
    final db = await database;
    await db.update('employees', emp.toMap(),
        where: 'id = ?', whereArgs: [emp.id]);
  }

  Future<void> deleteEmployee(String id) async {
    final db = await database;
    await db.update('employees', {'isActive': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ============ ATTENDANCE CRUD ============
  Future<void> insertAttendance(AttendanceRecord record) async {
    final db = await database;
    await db.insert('attendance', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAttendance(AttendanceRecord record) async {
    final db = await database;
    await db.update('attendance', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<List<AttendanceRecord>> getAttendanceByDate(String date) async {
    final db = await database;
    final maps = await db.query('attendance',
        where: 'date = ?', whereArgs: [date]);
    return maps.map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  Future<List<AttendanceRecord>> getEmployeeAttendance(
      String employeeId, String month) async {
    final db = await database;
    final maps = await db.query('attendance',
        where: 'employeeId = ? AND date LIKE ?',
        whereArgs: [employeeId, '$month%'],
        orderBy: 'date DESC');
    return maps.map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  Future<AttendanceRecord?> getTodayAttendance(
      String employeeId, String date) async {
    final db = await database;
    final maps = await db.query('attendance',
        where: 'employeeId = ? AND date = ?',
        whereArgs: [employeeId, date]);
    if (maps.isEmpty) return null;
    return AttendanceRecord.fromMap(maps.first);
  }

  Future<Map<String, int>> getMonthlyStats(
      String employeeId, String month) async {
    final db = await database;
    final maps = await db.query('attendance',
        where: 'employeeId = ? AND date LIKE ?',
        whereArgs: [employeeId, '$month%']);
    int present = 0, absent = 0, halfDay = 0, leave = 0;
    for (var m in maps) {
      switch (m['status']) {
        case 'present': present++; break;
        case 'absent': absent++; break;
        case 'half_day': halfDay++; break;
        case 'leave': leave++; break;
      }
    }
    return {
      'present': present,
      'absent': absent,
      'half_day': halfDay,
      'leave': leave,
    };
  }

  // ============ ADVANCES ============
  Future<void> insertAdvance(Map<String, dynamic> advance) async {
    final db = await database;
    await db.insert('advances', advance);
  }

  Future<List<Map<String, dynamic>>> getEmployeeAdvances(
      String employeeId) async {
    final db = await database;
    return await db.query('advances',
        where: 'employeeId = ? AND isPaid = 0', whereArgs: [employeeId]);
  }

  Future<double> getTotalAdvances(String employeeId, String month) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM advances WHERE employeeId = ? AND date LIKE ? AND isPaid = 0',
        [employeeId, '$month%']);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
