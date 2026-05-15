import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/employee_service.dart';
import '../models/employee.dart';
import 'add_employee_screen.dart';
import 'employee_detail_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final empService = context.watch<EmployeeService>();
    final filtered = empService.searchEmployees(_searchQuery);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text('Staff Management',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Staff dhundho...',
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _MiniStat(
                    label: 'Total Staff',
                    value: '${empService.employees.length}',
                    color: const Color(0xFF1A73E8)),
                const SizedBox(width: 12),
                ...empService.departmentStats.entries.take(2).map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _MiniStat(
                          label: e.key,
                          value: '${e.value}',
                          color: const Color(0xFF34A853),
                        ),
                      ),
                    ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Employee List
          Expanded(
            child: empService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Koi staff nahi.\n+ button se add karein.'
                                  : 'Koi result nahi mila.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _EmployeeCard(
                          employee: filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EmployeeDetailScreen(employee: filtered[i]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Staff Add Karein',
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1A73E8).withOpacity(0.1),
              backgroundImage: employee.faceImagePath != null
                  ? FileImage(
                      Uri.parse(employee.faceImagePath!).toFilePath()
                          as dynamic)
                  : null,
              child: employee.faceImagePath == null
                  ? Text(
                      employee.name.isNotEmpty
                          ? employee.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A73E8),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('${employee.designation} • ${employee.department}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(employee.phone,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 10),
                      const Icon(Icons.currency_rupee_rounded,
                          size: 12, color: Color(0xFF34A853)),
                      Text(
                        '${employee.monthlySalary.toStringAsFixed(0)}/mo',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF34A853),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (employee.faceImagePath != null)
                  const Icon(Icons.face_retouching_natural,
                      color: Color(0xFF1A73E8), size: 18),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
