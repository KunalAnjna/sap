import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/employee_service.dart';

class LocationTrackingScreen extends StatefulWidget {
  const LocationTrackingScreen({super.key});

  @override
  State<LocationTrackingScreen> createState() =>
      _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
  GoogleMapController? _mapController;
  bool _isLoading = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;

  // Distance tracking
  bool _isTracking = false;
  LocationData? _startPoint;
  LocationData? _endPoint;
  List<LatLng> _routePoints = [];
  double _totalDistance = 0.0; // meters
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  DateTime? _startTime;
  StreamSubscription<Position>? _positionStream;

  static const LatLng _defaultCenter = LatLng(28.4595, 77.0266);

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoading = true);
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final location = await locationService.getCurrentLocation();
    if (location != null && mounted) {
      final latLng = LatLng(location.latitude, location.longitude);
      setState(() => _currentLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _startTracking() async {
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final loc = await locationService.getCurrentLocation();
    if (loc == null) {
      _showSnack('Location permission nahi mila!');
      return;
    }

    final startLatLng = LatLng(loc.latitude, loc.longitude);
    setState(() {
      _isTracking = true;
      _startPoint = loc;
      _endPoint = null;
      _routePoints = [startLatLng];
      _totalDistance = 0.0;
      _elapsed = Duration.zero;
      _startTime = DateTime.now();
      _markers = {
        Marker(
          markerId: const MarkerId('start'),
          position: startLatLng,
          infoWindow: InfoWindow(title: 'Start', snippet: loc.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      };
      _polylines.clear();
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(startLatLng, 16));

    // Elapsed timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_startTime!));
    });

    // Live GPS stream — update every 10 meters
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position pos) {
      if (!_isTracking || !mounted) return;
      final newPoint = LatLng(pos.latitude, pos.longitude);
      setState(() {
        if (_routePoints.isNotEmpty) {
          final last = _routePoints.last;
          _totalDistance += Geolocator.distanceBetween(
            last.latitude, last.longitude,
            pos.latitude, pos.longitude,
          );
        }
        _routePoints.add(newPoint);
        _currentLocation = newPoint;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: List.from(_routePoints),
            color: const Color(0xFF1A73E8),
            width: 5,
            patterns: [],
          ),
        };
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPoint));
    });
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();
    _positionStream?.cancel();

    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final loc = await locationService.getCurrentLocation();

    setState(() {
      _isTracking = false;
      _endPoint = loc;
      if (loc != null) {
        final endLatLng = LatLng(loc.latitude, loc.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: endLatLng,
            infoWindow: InfoWindow(title: 'End', snippet: loc.address),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        // Fit map to show full route
        if (_routePoints.length > 1) {
          final bounds = _boundsFromLatLngList(_routePoints);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 60),
          );
        }
      }
    });

    _showSummaryDialog();
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    for (var p in list) {
      minLat = minLat == null ? p.latitude : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = maxLat == null ? p.latitude : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = minLng == null ? p.longitude : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = maxLng == null ? p.longitude : (p.longitude > maxLng ? p.longitude : maxLng);
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _showSummaryDialog() {
    final km = _totalDistance / 1000;
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60);
    final s = _elapsed.inSeconds.remainder(60);
    final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m ${s}s';
    final avgSpeed = _elapsed.inSeconds > 0
        ? (_totalDistance / _elapsed.inSeconds) * 3.6
        : 0.0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.flag_rounded, color: Color(0xFF34A853)),
            const SizedBox(width: 8),
            Text('Trip Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Big distance display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    km >= 1 ? '${km.toStringAsFixed(2)} km' : '${_totalDistance.toStringAsFixed(0)} m',
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A73E8),
                    ),
                  ),
                  Text('Total Distance', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SmallStat(
                    icon: Icons.timer_rounded,
                    label: 'Time',
                    value: timeStr,
                    color: const Color(0xFFFBBC04),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallStat(
                    icon: Icons.speed_rounded,
                    label: 'Avg Speed',
                    value: '${avgSpeed.toStringAsFixed(1)} km/h',
                    color: const Color(0xFF34A853),
                  ),
                ),
              ],
            ),
            if (_startPoint != null) ...[
              const Divider(height: 20),
              _AddressRow(label: 'Start', address: _startPoint!.address, color: const Color(0xFF34A853)),
              const SizedBox(height: 6),
            ],
            if (_endPoint != null)
              _AddressRow(label: 'End', address: _endPoint!.address, color: const Color(0xFFEA4335)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _markers.clear();
                _polylines.clear();
                _routePoints.clear();
                _totalDistance = 0;
                _elapsed = Duration.zero;
                _startPoint = null;
                _endPoint = null;
              });
            },
            child: Text('Naya Trip', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.poppins())));
  }

  String get _distanceDisplay {
    if (_totalDistance < 1000) return '${_totalDistance.toStringAsFixed(0)} m';
    return '${(_totalDistance / 1000).toStringAsFixed(2)} km';
  }

  String get _timeDisplay {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60);
    final s = _elapsed.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empService = context.watch<EmployeeService>();
    final avgSpeed = (_isTracking && _elapsed.inSeconds > 0)
        ? (_totalDistance / _elapsed.inSeconds) * 3.6
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Text('Location Tracking',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isTracking)
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadCurrentLocation),
        ],
      ),
      body: Column(
        children: [
          // MAP
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? _defaultCenter,
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (c) => _mapController = c,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8))),
                  ),
                // LIVE badge
                if (_isTracking)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text('LIVE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // LIVE STATS (tracking ke dauran)
          if (_isTracking)
            Container(
              color: const Color(0xFF0D47A1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LiveStat(icon: Icons.straighten_rounded, label: 'Distance', value: _distanceDisplay),
                  _LiveStat(icon: Icons.timer_rounded, label: 'Time', value: _timeDisplay),
                  _LiveStat(icon: Icons.speed_rounded, label: 'Speed', value: '${avgSpeed.toStringAsFixed(1)} km/h'),
                ],
              ),
            ),

          // START / STOP BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking ? const Color(0xFFEA4335) : const Color(0xFF34A853),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  _isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 24,
                ),
                label: Text(
                  _isTracking ? 'Stop Karo & Distance Dekho' : 'Start Tracking',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _isTracking ? _stopTracking : _startTracking,
              ),
            ),
          ),

          // RESULT CARD (tracking ke baad)
          if (!_isTracking && _startPoint != null && _totalDistance > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ResultStat(
                          icon: Icons.straighten_rounded,
                          label: 'Distance',
                          value: _distanceDisplay,
                          color: const Color(0xFF1A73E8),
                        ),
                        Container(width: 1, height: 36, color: Colors.grey[200]),
                        _ResultStat(
                          icon: Icons.timer_rounded,
                          label: 'Time',
                          value: _timeDisplay,
                          color: const Color(0xFFFBBC04),
                        ),
                        Container(width: 1, height: 36, color: Colors.grey[200]),
                        _ResultStat(
                          icon: Icons.speed_rounded,
                          label: 'Avg Speed',
                          value: _elapsed.inSeconds > 0
                              ? '${((_totalDistance / _elapsed.inSeconds) * 3.6).toStringAsFixed(1)} km/h'
                              : '--',
                          color: const Color(0xFF34A853),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    if (_startPoint != null)
                      _AddressRow(label: 'Start', address: _startPoint!.address, color: const Color(0xFF34A853)),
                    const SizedBox(height: 4),
                    if (_endPoint != null)
                      _AddressRow(label: 'End', address: _endPoint!.address, color: const Color(0xFFEA4335)),
                  ],
                ),
              ),
            ),

          // EMPLOYEE LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                Text('Staff', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (empService.employees.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Koi staff nahi', style: GoogleFonts.poppins(color: Colors.grey)),
                    ),
                  )
                else
                  ...empService.employees.map((emp) =>
                      _EmployeeTile(name: emp.name, designation: emp.designation)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Helper Widgets ----

class _LiveStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _LiveStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 15),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ResultStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SmallStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String label;
  final String address;
  final Color color;
  const _AddressRow({required this.label, required this.address, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(address,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final String name;
  final String designation;
  const _EmployeeTile({required this.name, required this.designation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A73E8).withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A73E8), fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(designation, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Text('Offline', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
