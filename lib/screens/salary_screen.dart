import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/employee_service.dart';
import '../services/attendance_service.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final _months = List.generate(12, (i) {
    final d = DateTime.now().subtract(Duration(days: i * 30));
    return DateFormat('yyyy-MM').format(d);
  });

  @override
  Widget build(BuildContext context) {
    final empService = context.watch<EmployeeService>();
    final employees = empService.employees;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text('Salary Management',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            color: const Color(0xFF1A73E8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButtonFormField<String>(
              value: _selectedMonth,
              dropdownColor: const Color(0xFF1A73E8),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Month chunein',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                prefixIcon: const Icon(Icons.calendar_month,
                    color: Colors.white70, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.white30),
                ),
              ),
              items: _months
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          DateFormat('MMMM yyyy')
                              .format(DateTime.parse('$m-01')),
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: (m) => setState(() => _selectedMonth = m ?? _selectedMonth),
            ),
          ),

          // Total Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Total Staff',
                  value: '${employees.length}',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF1A73E8),
                ),
                _SummaryItem(
                  label: 'Total Payable',
                  value:
                      '₹${employees.fold<double>(0, (s, e) => s + e.monthlySalary).toStringAsFixed(0)}',
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF34A853),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: employees.isEmpty
                ? Center(
                    child: Text('Koi staff nahi',
                        style: GoogleFonts.poppins(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: employees.length,
                    itemBuilder: (_, i) {
                      final emp = employees[i];
                      return _SalaryCard(
                        employeeId: emp.id,
                        name: emp.name,
                        designation: emp.designation,
                        monthlySalary: emp.monthlySalary,
                        month: _selectedMonth,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}

class _SalaryCard extends StatefulWidget {
  final String employeeId;
  final String name;
  final String designation;
  final double monthlySalary;
  final String month;

  const _SalaryCard({
    required this.employeeId,
    required this.name,
    required this.designation,
    required this.monthlySalary,
    required this.month,
  });

  @override
  State<_SalaryCard> createState() => _SalaryCardState();
}

class _SalaryCardState extends State<_SalaryCard> {
  Map<String, int> _stats = {};
  bool _loading = true;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(_SalaryCard old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month) _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final attService =
        Provider.of<AttendanceService>(context, listen: false);
    _stats = await attService.getMonthlyStats(widget.employeeId, widget.month);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final present = _stats['present'] ?? 0;
    final absent = _stats['absent'] ?? 0;
    final halfDay = _stats['half_day'] ?? 0;
    final perDay = widget.monthlySalary / 26;
    final earned =
        (present * perDay) + (halfDay * perDay * 0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          const Color(0xFF1A73E8).withOpacity(0.1),
                      child: Text(
                        widget.name.isNotEmpty
                            ? widget.name[0].toUpperCase()
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
                          Text(widget.name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(widget.designation,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${earned.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF34A853),
                            )),
                        Text('Net Payable',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MiniChip(
                        '$present Present', const Color(0xFF34A853)),
                    _MiniChip(
                        '$absent Absent', const Color(0xFFEA4335)),
                    _MiniChip(
                        '$halfDay Half', const Color(0xFFFBBC04)),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isPaid = !_isPaid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isPaid
                                  ? '✓ ${widget.name} ko ₹${earned.toStringAsFixed(0)} pay kiya'
                                  : 'Payment undo kiya',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: _isPaid
                                ? const Color(0xFF34A853)
                                : Colors.grey,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isPaid
                              ? const Color(0xFF34A853)
                              : const Color(0xFF1A73E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isPaid ? '✓ Paid' : 'Pay Now',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
