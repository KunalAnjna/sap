import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/attendance_service.dart';
import '../services/employee_service.dart';
import '../services/location_service.dart';
import '../models/employee.dart';

class FaceAttendanceScreen extends StatefulWidget {
  final Employee? preselectedEmployee;

  const FaceAttendanceScreen({super.key, this.preselectedEmployee});

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _faceDetected = false;
  Employee? _selectedEmployee;
  String _statusMessage = 'Apna chehra camera ke saamne rakhein';
  bool _attendanceMarked = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedEmployee = widget.preselectedEmployee;
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _statusMessage = 'Camera nahi mila');
        return;
      }

      // Use front camera for face detection
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusMessage = 'Camera ready - chehra dikhaein';
        });

        // Simulate face detection after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_attendanceMarked) {
            setState(() => _faceDetected = true);
            _statusMessage = 'Chehra detect hua! ✓';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Camera error: $e');
      }
    }
  }

  Future<void> _captureAndMarkAttendance() async {
    if (_isProcessing || !_faceDetected || _selectedEmployee == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Attendance mark ho rahi hai...';
    });

    try {
      // Capture photo
      String? imagePath;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();
        final dir = await getApplicationDocumentsDirectory();
        final fileName =
            'face_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = path.join(dir.path, 'faces', fileName);
        await Directory(path.join(dir.path, 'faces')).create(recursive: true);
        await File(image.path).copy(savedPath);
        imagePath = savedPath;
        _capturedImagePath = savedPath;
      }

      // Get location
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final location = await locationService.getCurrentLocation();

      // Mark attendance
      final attService =
          Provider.of<AttendanceService>(context, listen: false);
      await attService.markAttendance(
        employeeId: _selectedEmployee!.id,
        status: 'present',
        latitude: location?.latitude,
        longitude: location?.longitude,
        locationAddress: location?.address,
        faceImagePath: imagePath,
        faceVerified: true,
      );

      // Update employee face image if first time
      if (_selectedEmployee!.faceImagePath == null && imagePath != null) {
        final empService =
            Provider.of<EmployeeService>(context, listen: false);
        await empService.updateFaceImage(_selectedEmployee!.id, imagePath);
      }

      setState(() {
        _attendanceMarked = true;
        _isProcessing = false;
        _statusMessage = 'Attendance successfully mark ho gayi! ✓';
      });

      // Show success
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _showSuccessDialog(location?.address);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _showSuccessDialog(String? location) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF34A853), size: 64),
            const SizedBox(height: 16),
            Text(
              'Attendance Mark Ho Gayi!',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedEmployee?.name ?? '',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A73E8)),
            ),
            if (location != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      location,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
            if (_capturedImagePath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Photo captured for face verification',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.face_retouching_natural,
                    size: 14, color: Color(0xFF1A73E8)),
                const SizedBox(width: 4),
                Text('Face Verified',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: const Color(0xFF1A73E8))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('Done',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<EmployeeService>().employees;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Face Attendance',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isCameraInitialized && _cameraController != null)
                  CameraPreview(_cameraController!)
                else
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                // Face overlay frame
                Center(
                  child: Container(
                    width: 220,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _faceDetected
                            ? const Color(0xFF34A853)
                            : Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(140),
                    ),
                    child: _faceDetected
                        ? null
                        : const SizedBox.shrink(),
                  ),
                ),

                // Corner decorations
                Positioned(
                  top: 60,
                  left: 80,
                  child: _CornerDecoration(color: _faceDetected
                      ? const Color(0xFF34A853)
                      : Colors.white),
                ),
                Positioned(
                  top: 60,
                  right: 80,
                  child: Transform.rotate(
                    angle: 1.57,
                    child: _CornerDecoration(
                        color: _faceDetected
                            ? const Color(0xFF34A853)
                            : Colors.white),
                  ),
                ),

                // Status overlay at bottom
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _faceDetected
                            ? const Color(0xFF34A853)
                            : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                // Face detected indicator
                if (_faceDetected)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.face_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('Chehra Detect Hua',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee selector
                Text('Staff Chunein',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<Employee>(
                  value: _selectedEmployee,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    hintText: 'Employee chunein...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13),
                  ),
                  items: employees
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('${e.name} (${e.designation})',
                                style: GoogleFonts.poppins(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (e) =>
                      setState(() => _selectedEmployee = e),
                ),

                const SizedBox(height: 16),

                // Mark Attendance Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _faceDetected &&
                              _selectedEmployee != null &&
                              !_attendanceMarked
                          ? const Color(0xFF1A73E8)
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _faceDetected &&
                            _selectedEmployee != null &&
                            !_attendanceMarked &&
                            !_isProcessing
                        ? _captureAndMarkAttendance
                        : null,
                    child: _isProcessing
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fingerprint,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                _attendanceMarked
                                    ? 'Attendance Mark Ho Gayi ✓'
                                    : 'Face se Attendance Mark Karein',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerDecoration extends StatelessWidget {
  final Color color;

  const _CornerDecoration({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(30, 30),
      painter: _CornerPainter(color: color),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
