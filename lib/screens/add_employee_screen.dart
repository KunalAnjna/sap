import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/employee_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _department = 'Sales';
  String _salaryType = 'monthly';
  bool _isSaving = false;

  final _departments = [
    'Sales', 'Operations', 'HR', 'Finance', 'IT', 'Marketing',
    'Production', 'Security', 'Admin', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text('Naya Staff Add Karein',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Card
              _SectionCard(
                title: 'Basic Jankari',
                icon: Icons.person_rounded,
                children: [
                  _FormField(
                    controller: _nameCtrl,
                    label: 'Poora Naam *',
                    hint: 'e.g. Ramesh Kumar',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Naam zaruri hai' : null,
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    controller: _phoneCtrl,
                    label: 'Mobile Number *',
                    hint: '10 digit mobile number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) {
                      if (v == null || v.length != 10) {
                        return 'Valid 10 digit number dalein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    controller: _designationCtrl,
                    label: 'Designation *',
                    hint: 'e.g. Sales Executive',
                    icon: Icons.work_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Designation zaruri hai' : null,
                  ),
                  const SizedBox(height: 14),
                  // Department Dropdown
                  DropdownButtonFormField<String>(
                    value: _department,
                    decoration: InputDecoration(
                      labelText: 'Department *',
                      labelStyle:
                          GoogleFonts.poppins(fontSize: 13),
                      prefixIcon: const Icon(Icons.business_outlined,
                          size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    items: _departments
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  style: GoogleFonts.poppins(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (d) =>
                        setState(() => _department = d ?? 'Sales'),
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    controller: _addressCtrl,
                    label: 'Address (Optional)',
                    hint: 'Ghar ka address',
                    icon: Icons.home_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Salary Card
              _SectionCard(
                title: 'Salary Details',
                icon: Icons.payments_rounded,
                children: [
                  // Salary Type
                  Text('Salary Type',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SalaryTypeChip(
                        label: 'Monthly',
                        icon: Icons.calendar_month,
                        selected: _salaryType == 'monthly',
                        onTap: () =>
                            setState(() => _salaryType = 'monthly'),
                      ),
                      const SizedBox(width: 8),
                      _SalaryTypeChip(
                        label: 'Daily',
                        icon: Icons.today_rounded,
                        selected: _salaryType == 'daily',
                        onTap: () =>
                            setState(() => _salaryType = 'daily'),
                      ),
                      const SizedBox(width: 8),
                      _SalaryTypeChip(
                        label: 'Hourly',
                        icon: Icons.access_time_rounded,
                        selected: _salaryType == 'hourly',
                        onTap: () =>
                            setState(() => _salaryType = 'hourly'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _salaryCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _salaryType == 'monthly'
                          ? 'Monthly Salary (₹) *'
                          : _salaryType == 'daily'
                              ? 'Daily Wage (₹) *'
                              : 'Hourly Rate (₹) *',
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      prefixIcon: const Icon(
                          Icons.currency_rupee_rounded, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Salary amount zaruri hai' : null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _isSaving ? null : _saveEmployee,
                  child: _isSaving
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Staff Save Karein',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                )),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final salary = double.parse(_salaryCtrl.text);
      await Provider.of<EmployeeService>(context, listen: false).addEmployee(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        designation: _designationCtrl.text.trim(),
        department: _department,
        monthlySalary: salary,
        salaryType: _salaryType,
        dailyWage: _salaryType == 'daily' ? salary : salary / 26,
        address: _addressCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${_nameCtrl.text} successfully add ho gaye!',
                style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF34A853),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _designationCtrl.dispose();
    _salaryCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1A73E8), size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFF1A73E8))),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _SalaryTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SalaryTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A73E8)
              : const Color(0xFF1A73E8).withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF1A73E8)
                : const Color(0xFF1A73E8).withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF1A73E8)),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: selected ? Colors.white : const Color(0xFF1A73E8),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
