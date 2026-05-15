import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/employee_service.dart';
import '../services/attendance_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final empService = context.watch<EmployeeService>();
    final attService = context.watch<AttendanceService>();
    final totalSalary = empService.employees
        .fold<double>(0, (s, e) => s + e.monthlySalary);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text('Reports',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          _SectionTitle('Is Mahine Ka Summary'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _ReportCard(
                icon: Icons.people_rounded,
                label: 'Total Staff',
                value: '${empService.employees.length}',
                color: const Color(0xFF1A73E8),
              ),
              _ReportCard(
                icon: Icons.currency_rupee_rounded,
                label: 'Total Payroll',
                value: '₹${(totalSalary / 1000).toStringAsFixed(1)}K',
                color: const Color(0xFF34A853),
              ),
              _ReportCard(
                icon: Icons.check_circle_rounded,
                label: 'Aaj Present',
                value: '${attService.todayStats['present'] ?? 0}',
                color: const Color(0xFF34A853),
              ),
              _ReportCard(
                icon: Icons.cancel_rounded,
                label: 'Aaj Absent',
                value: '${attService.todayStats['absent'] ?? 0}',
                color: const Color(0xFFEA4335),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _SectionTitle('Department Report'),
          const SizedBox(height: 10),
          ...empService.departmentStats.entries.map((e) =>
              _DepartmentBar(
                department: e.key,
                count: e.value,
                total: empService.employees.length,
              )),

          const SizedBox(height: 20),
          _SectionTitle('Quick Actions'),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Salary Slip Generate Karo',
            subtitle: 'PDF format mein salary slip',
            color: const Color(0xFFEA4335),
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.table_chart_rounded,
            title: 'Attendance Report Export',
            subtitle: 'Excel/CSV format mein download',
            color: const Color(0xFF34A853),
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.share_rounded,
            title: 'Report Share Karo',
            subtitle: 'WhatsApp ya Email se bhejo',
            color: const Color(0xFF1A73E8),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, fontSize: 15));
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReportCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _DepartmentBar extends StatelessWidget {
  final String department;
  final int count;
  final int total;

  const _DepartmentBar({
    required this.department,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? count / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(department,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              Text('$count staff',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1A73E8)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
