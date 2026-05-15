import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../services/employee_service.dart';
import '../models/employee.dart';
import 'face_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isMarkingAll = false;

  @override
  Widget build(BuildContext context) {
    final attService = context.watch<AttendanceService>();
    final empService = context.watch<EmployeeService>();
    final employees = empService.employees;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final displayDate = DateFormat('dd MMM, EEEE').format(_selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text('Attendance',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.face_retouching_natural),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const FaceAttendanceScreen()),
            ),
            tooltip: 'Face Attendance',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            color: const Color(0xFF1A73E8),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white),
                      onPressed: () => setState(() {
                        _selectedDate = _selectedDate
                            .subtract(const Duration(days: 1));
                        attService.loadDateRecords(DateFormat('yyyy-MM-dd')
                            .format(_selectedDate));
                      }),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Column(
                        children: [
                          Text(displayDate,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          if (isToday)
                            Text('Aaj',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                      onPressed: isToday
                          ? null
                          : () => setState(() {
                                _selectedDate = _selectedDate
                                    .add(const Duration(days: 1));
                              }),
                    ),
                  ],
                ),

                // Stats Row
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DateStat(
                        label: 'Present',
                        value: '${attService.todayStats['present'] ?? 0}',
                        color: const Color(0xFF34A853)),
                    _DateStat(
                        label: 'Absent',
                        value: '${attService.todayStats['absent'] ?? 0}',
                        color: const Color(0xFFEA4335)),
                    _DateStat(
                        label: 'Half Day',
                        value: '${attService.todayStats['half_day'] ?? 0}',
                        color: const Color(0xFFFBBC04)),
                    _DateStat(
                        label: 'Total',
                        value: '${employees.length}',
                        color: Colors.white),
                  ],
                ),
              ],
            ),
          ),

          // Employee List
          Expanded(
            child: employees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('Pehle staff add karein',
                            style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: employees.length,
                    itemBuilder: (_, i) {
                      final emp = employees[i];
                      final record = attService.todayRecords[emp.id];
                      return _AttendanceMarkCard(
                        employee: emp,
                        record: record,
                        isToday: isToday,
                        onMark: (status) => _markAttendance(
                            emp, status, attService),
                        onFaceAttendance: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FaceAttendanceScreen(
                                preselectedEmployee: emp),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: employees.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isMarkingAll ? null : () => _markAllPresent(attService, employees),
              backgroundColor: const Color(0xFF34A853),
              icon: _isMarkingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.done_all_rounded, color: Colors.white),
              label: Text('Sab Present Mark Karein',
                  style: GoogleFonts.poppins(color: Colors.white)),
            )
          : null,
    );
  }

  Future<void> _markAttendance(
      Employee emp, String status, AttendanceService attService) async {
    await attService.manualMarkAttendance(
      employeeId: emp.id,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      status: status,
    );
  }

  Future<void> _markAllPresent(
      AttendanceService attService, List<Employee> employees) async {
    setState(() => _isMarkingAll = true);
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    for (var emp in employees) {
      final existing = attService.todayRecords[emp.id];
      if (existing == null) {
        await attService.manualMarkAttendance(
          employeeId: emp.id,
          date: date,
          status: 'present',
        );
      }
    }
    setState(() => _isMarkingAll = false);
  }
}

class _DateStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DateStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}

class _AttendanceMarkCard extends StatelessWidget {
  final Employee employee;
  final dynamic record;
  final bool isToday;
  final Function(String) onMark;
  final VoidCallback onFaceAttendance;

  const _AttendanceMarkCard({
    required this.employee,
    this.record,
    required this.isToday,
    required this.onMark,
    required this.onFaceAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final status = record?.status ?? 'not_marked';
    final punchIn = record?.punchInTime;
    final punchOut = record?.punchOutTime;
    final faceVerified = record?.faceVerified ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      const Color(0xFF1A73E8).withOpacity(0.1),
                  child: Text(
                    employee.name.isNotEmpty
                        ? employee.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A73E8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(employee.name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          if (faceVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                size: 14, color: Color(0xFF1A73E8)),
                          ],
                        ],
                      ),
                      Text(employee.designation,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[600])),
                      if (punchIn != null)
                        Text(
                          'In: $punchIn${punchOut != null ? " | Out: $punchOut" : " (Abhi tak in)"}',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                // Face attendance button
                IconButton(
                  icon: const Icon(Icons.face_retouching_natural,
                      color: Color(0xFF1A73E8), size: 22),
                  onPressed: onFaceAttendance,
                ),
              ],
            ),
          ),

          // Status Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _StatusButton(
                    label: 'Present',
                    color: const Color(0xFF34A853),
                    selected: status == 'present',
                    onTap: () => onMark('present')),
                const SizedBox(width: 6),
                _StatusButton(
                    label: 'Absent',
                    color: const Color(0xFFEA4335),
                    selected: status == 'absent',
                    onTap: () => onMark('absent')),
                const SizedBox(width: 6),
                _StatusButton(
                    label: 'Half Day',
                    color: const Color(0xFFFBBC04),
                    selected: status == 'half_day',
                    onTap: () => onMark('half_day')),
                const SizedBox(width: 6),
                _StatusButton(
                    label: 'Leave',
                    color: Colors.grey,
                    selected: status == 'leave',
                    onTap: () => onMark('leave')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
