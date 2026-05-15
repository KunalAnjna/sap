import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/employee_service.dart';
import '../services/attendance_service.dart';
import 'face_attendance_screen.dart';
import 'location_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final empService = context.watch<EmployeeService>();
    final attService = context.watch<AttendanceService>();
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd MMM yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A73E8),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '👋 Namaste, Admin!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.white24,
                              radius: 22,
                              child: const Icon(Icons.business_rounded,
                                  color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      _StatCard(
                        title: 'Total Staff',
                        value: '${empService.employees.length}',
                        icon: Icons.people_rounded,
                        color: const Color(0xFF1A73E8),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'Present Today',
                        value:
                            '${attService.todayStats['present'] ?? 0}',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF34A853),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        title: 'Absent Today',
                        value:
                            '${attService.todayStats['absent'] ?? 0}',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFEA4335),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'Half Day',
                        value:
                            '${attService.todayStats['half_day'] ?? 0}',
                        icon: Icons.timelapse_rounded,
                        color: const Color(0xFFFBBC04),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Quick Actions
                  _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.face_retouching_natural,
                          title: 'Face\nAttendance',
                          color: const Color(0xFF1A73E8),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FaceAttendanceScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.location_on_rounded,
                          title: 'Live\nTracking',
                          color: const Color(0xFF34A853),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const LocationTrackingScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.edit_calendar_rounded,
                          title: 'Mark\nAttendance',
                          color: const Color(0xFFFBBC04),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.payments_rounded,
                          title: 'Pay\nSalary',
                          color: const Color(0xFFEA4335),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Today's Attendance Overview
                  _SectionHeader(title: "Today's Attendance"),
                  const SizedBox(height: 12),
                  if (empService.employees.isEmpty)
                    _EmptyState(
                      icon: Icons.people_outline,
                      message: 'Koi staff nahi mila.\nPehle staff add karein.',
                    )
                  else
                    ...empService.employees.take(5).map((emp) {
                      final record = attService.todayRecords[emp.id];
                      return _AttendanceTile(
                        name: emp.name,
                        designation: emp.designation,
                        status: record?.status ?? 'not_marked',
                        punchIn: record?.punchInTime,
                        punchOut: record?.punchOutTime,
                        faceVerified: record?.faceVerified ?? false,
                      );
                    }),

                  if (empService.employees.length > 5)
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Aur ${empService.employees.length - 5} staff dekho',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF1A73E8)),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
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
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          'Sab dekho',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF1A73E8),
          ),
        ),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final String name;
  final String designation;
  final String status;
  final String? punchIn;
  final String? punchOut;
  final bool faceVerified;

  const _AttendanceTile({
    required this.name,
    required this.designation,
    required this.status,
    this.punchIn,
    this.punchOut,
    this.faceVerified = false,
  });

  Color get _statusColor {
    switch (status) {
      case 'present': return const Color(0xFF34A853);
      case 'absent': return const Color(0xFFEA4335);
      case 'half_day': return const Color(0xFFFBBC04);
      case 'leave': return const Color(0xFF9E9E9E);
      default: return const Color(0xFFBDBDBD);
    }
  }

  String get _statusText {
    switch (status) {
      case 'present': return 'Present';
      case 'absent': return 'Absent';
      case 'half_day': return 'Half Day';
      case 'leave': return 'Leave';
      default: return 'Mark Karein';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF1A73E8).withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                    Text(name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    if (faceVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 14, color: Color(0xFF1A73E8)),
                    ],
                  ],
                ),
                Text(designation,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[600])),
                if (punchIn != null)
                  Text(
                    punchOut != null
                        ? 'In: $punchIn | Out: $punchOut'
                        : 'In: $punchIn',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor.withOpacity(0.3)),
            ),
            child: Text(
              _statusText,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
