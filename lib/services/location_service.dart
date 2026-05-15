import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
  });
}

class EmployeeLocationTrack {
  final String employeeId;
  final String employeeName;
  final List<LocationData> locations;
  final DateTime lastUpdated;

  EmployeeLocationTrack({
    required this.employeeId,
    required this.employeeName,
    required this.locations,
    required this.lastUpdated,
  });

  LocationData? get latestLocation =>
      locations.isNotEmpty ? locations.last : null;
}

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  String _currentAddress = '';
  bool _isTracking = false;
  bool _hasPermission = false;

  // Simulated employee tracking (in real app, use Firebase/backend)
  final Map<String, EmployeeLocationTrack> _employeeTracks = {};

  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  Map<String, EmployeeLocationTrack> get employeeTracks => _employeeTracks;

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _hasPermission = false;
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _hasPermission = false;
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _hasPermission = false;
      notifyListeners();
      return false;
    }

    _hasPermission = true;
    notifyListeners();
    return true;
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPerms = await checkAndRequestPermission();
      if (!hasPerms) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentAddress = await _getAddressFromCoords(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      notifyListeners();

      return LocationData(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  Future<String> _getAddressFromCoords(
      double latitude, double longitude) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.name,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).toList();
        return parts.take(3).join(', ');
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return '$latitude, $longitude';
  }

  void addEmployeeLocation(
      String employeeId, String employeeName, LocationData location) {
    final existing = _employeeTracks[employeeId];
    if (existing != null) {
      final updated = EmployeeLocationTrack(
        employeeId: employeeId,
        employeeName: employeeName,
        locations: [...existing.locations, location],
        lastUpdated: DateTime.now(),
      );
      _employeeTracks[employeeId] = updated;
    } else {
      _employeeTracks[employeeId] = EmployeeLocationTrack(
        employeeId: employeeId,
        employeeName: employeeName,
        locations: [location],
        lastUpdated: DateTime.now(),
      );
    }
    notifyListeners();
  }

  double getDistanceFromOffice(
      double empLat, double empLon, double officeLat, double officeLon) {
    return Geolocator.distanceBetween(empLat, empLon, officeLat, officeLon);
  }

  bool isWithinOfficeRadius(double empLat, double empLon,
      double officeLat, double officeLon,
      {double radiusMeters = 200}) {
    final distance =
        getDistanceFromOffice(empLat, empLon, officeLat, officeLon);
    return distance <= radiusMeters;
  }

  void startTracking() {
    _isTracking = true;
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }
}
