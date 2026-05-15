import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/employee.dart';
import '../services/attendance_service.dart';
import '../services/employee_service.dart';
import '../models/attendance_record.dart';
import 'face_attendance_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AttendanceRecord> _attendanceRecords = [];
  Map<String, int> _monthlyStats = {};
  bool _loadingAttendance = false;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _loadingAttendance = true);
    final attService =
        Provider.of<AttendanceService>(context, listen: false);
    final month = DateFormat('yyyy-MM').format(_focusedDay);
    _attendanceRecords = await attService.getEmployeeAttendance(
        widget.employee.id, month);
    _monthlyStats =
        await attService.getMonthlyStats(widget.employee.id, month);
    setState(() => _loadingAttendance = false);
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employee;
    final present = _monthlyStats['present'] ?? 0;
    final absent = _monthlyStats['absent'] ?? 0;
    final halfDay = _monthlyStats['half_day'] ?? 0;
    final earnedSalary =
        (present * (emp.monthlySalary / 26)) + (halfDay * (emp.monthlySalary / 26) * 0.5);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1A73E8),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child: Text(
                          emp.name.isNotEmpty
                              ? emp.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(emp.name,
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text('${emp.designation} • ${emp.department}',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13)),
                      Text(emp.phone,
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF1A73E8),
                labelColor: const Color(0xFF1A73E8),
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Salary'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Overview Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats Row
                Row(
                  children: [
                    _StatBox(
                        label: 'Present',
                        value: '$present',
                        color: const Color(0xFF34A853)),
                    const SizedBox(width: 10),
                    _StatBox(
                        label: 'Absent',
                        value: '$absent',
                        color: const Color(0xFFEA4335)),
                    const SizedBox(width: 10),
                    _StatBox(
                        label: 'Half Day',
                        value: '$halfDay',
                        color: const Color(0xFFFBBC04)),
                  ],
                ),
                const SizedBox(height: 16),
                // Salary Card
                _InfoCard(
                  title: 'Salary This Month',
                  children: [
                    _InfoRow('Monthly Salary',
                        '₹${emp.monthlySalary.toStringAsFixed(0)}'),
                    _InfoRow(
                        'Earned (${present}d present)',
                        '₹${earnedSalary.toStringAsFixed(0)}'),
                    _InfoRow('Salary Type', emp.salaryType),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Staff Details',
                  children: [
                    _InfoRow('Employee Code', emp.employeeCode ?? '--'),
                    _InfoRow('Joining Date', emp.joiningDate),
                    _InfoRow('Phone', emp.phone),
                    if (emp.address != null)
                      _InfoRow('Address', emp.address!),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.face_retouching_natural,
                            color: Colors.white, size: 18),
                        label: Text('Face Attendance',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FaceAttendanceScreen(
                                preselectedEmployee: emp),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFEA4335)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFEA4335), size: 18),
                        label: Text('Delete',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFFEA4335),
                                fontWeight: FontWeight.w600)),
                        onPressed: _confirmDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Attendance Tab
            _loadingAttendance
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2024, 1, 1),
                        lastDay: DateTime.utc(2026, 12, 31),
                        focusedDay: _focusedDay,
                        onDaySelected: (selected, focused) {
                          setState(() => _focusedDay = focused);
                        },
                        onPageChanged: (focused) {
                          setState(() => _focusedDay = focused);
                          _loadAttendance();
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: const BoxDecoration(
                            color: Color(0xFF1A73E8),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: const Color(0xFF1A73E8).withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        eventLoader: (day) {
                          final dateStr =
                              DateFormat('yyyy-MM-dd').format(day);
                          return _attendanceRecords
                              .where((r) => r.date == dateStr)
                              .toList();
                        },
                      ),
                      Expanded(
                        child: _attendanceRecords.isEmpty
                            ? Center(
                                child: Text('Is mahine ka koi record nahi',
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _attendanceRecords.length,
                                itemBuilder: (_, i) {
                                  final r = _attendanceRecords[i];
                                  return _AttendanceHistoryTile(record: r);
                                },
                              ),
                      ),
                    ],
                  ),

            // Salary Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SalaryCard(
                  employee: emp,
                  present: present,
                  absent: absent,
                  halfDay: halfDay,
                  earnedSalary: earnedSalary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Staff Delete Karein?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('${widget.employee.name} ko delete karein?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA4335)),
            onPressed: () async {
              await Provider.of<EmployeeService>(context, listen: false)
                  .deleteEmployee(widget.employee.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child:
                Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(_, __, ___) => Container(
      color: Colors.white, child: tabBar);

  @override
  bool shouldRebuild(_) => false;
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[600])),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AttendanceHistoryTile extends StatelessWidget {
  final AttendanceRecord record;
  const _AttendanceHistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (record.status) {
      case 'present': color = const Color(0xFF34A853); break;
      case 'absent': color = const Color(0xFFEA4335); break;
      case 'half_day': color = const Color(0xFFFBBC04); break;
      default: color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.date,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                if (record.punchInTime != null)
                  Text(
                    'In: ${record.punchInTime}'
                    '${record.punchOutTime != null ? " | Out: ${record.punchOutTime}" : ""}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              if (record.faceVerified)
                const Icon(Icons.face_retouching_natural,
                    size: 14, color: Color(0xFF1A73E8)),
              if (record.latitude != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.location_on_rounded,
                      size: 14, color: Color(0xFF34A853)),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.status == 'present'
                      ? 'Present'
                      : record.status == 'absent'
                          ? 'Absent'
                          : record.status == 'half_day'
                              ? 'Half Day'
                              : record.status,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalaryCard extends StatelessWidget {
  final Employee employee;
  final int present;
  final int absent;
  final int halfDay;
  final double earnedSalary;

  const _SalaryCard({
    required this.employee,
    required this.present,
    required this.absent,
    required this.halfDay,
    required this.earnedSalary,
  });

  @override
  Widget build(BuildContext context) {
    final perDay = employee.monthlySalary / 26;
    final halfDayDeduction = halfDay * perDay * 0.5;
    final absentDeduction = absent * perDay;
    final netSalary = earnedSalary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Salary Calculation',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const Divider(height: 20),
          _SalaryRow(
              'Monthly CTC', '₹${employee.monthlySalary.toStringAsFixed(0)}'),
          _SalaryRow('Working Days', '26 days'),
          _SalaryRow('Per Day Rate', '₹${perDay.toStringAsFixed(0)}'),
          const Divider(height: 20),
          _SalaryRow('Present Days', '$present days', isGreen: true),
          _SalaryRow('Absent Deduction',
              '-₹${absentDeduction.toStringAsFixed(0)}',
              isRed: true),
          _SalaryRow('Half Day Deduction',
              '-₹${halfDayDeduction.toStringAsFixed(0)}',
              isRed: true),
          const Divider(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF34A853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Payable',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹${netSalary.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: const Color(0xFF34A853))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.payments_rounded, color: Colors.white),
              label: Text('Salary Pay Karein',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '₹${netSalary.toStringAsFixed(0)} ${employee.name} ko pay kiya',
                        style: GoogleFonts.poppins()),
                    backgroundColor: const Color(0xFF34A853),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SalaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;
  final bool isRed;

  const _SalaryRow(this.label, this.value,
      {this.isGreen = false, this.isRed = false});

  @override
  Widget build(BuildContext context) {
    final color = isGreen
        ? const Color(0xFF34A853)
        : isRed
            ? const Color(0xFFEA4335)
            : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[600])),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
