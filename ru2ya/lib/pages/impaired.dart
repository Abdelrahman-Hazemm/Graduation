import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class ImpairedPage extends StatefulWidget {
  const ImpairedPage({Key? key}) : super(key: key);

  @override
  State<ImpairedPage> createState() => _ImpairedPageState();
}

class _ImpairedPageState extends State<ImpairedPage> {
  final String blindUserId = "blind_user_1";
  Timer? _locationTimer;
  Timer? _apiTimer;
  bool _isTracking = false;
  String _statusMessage = "Initializing location tracking...";

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _startApiMonitoring(); // Starts the API listener when page opens
  }

  Future<void> _initLocationTracking() async {
    final permissionGranted = await _checkLocationPermission();
    if (permissionGranted) {
      _startLocationUpdates();
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = "Location services are disabled. Please enable them.";
      });
      return false;
    }

    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
      if (status.isDenied) {
        setState(() {
          _statusMessage = "Location permission denied.";
        });
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      setState(() {
        _statusMessage =
            "Location permission permanently denied. Enable it in settings.";
      });
      openAppSettings();
      return false;
    }

    return true;
  }

  void _startLocationUpdates() {
    if (_locationTimer != null) return;

    setState(() {
      _isTracking = true;
      _statusMessage = "Tracking and sending your location every 10 seconds...";
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _sendLocationToFirebase(position);
      } catch (e) {
        print("Error getting location: $e");
        setState(() {
          _statusMessage = "Error getting location: $e";
        });
      }
    });
  }

  Future<void> _sendLocationToFirebase(Position position) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('blind_users')
          .doc(blindUserId);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          'location': GeoPoint(position.latitude, position.longitude),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'name': 'Jane',
          'assignedCaregivers': ['caregiver_1'],
          'location': GeoPoint(position.latitude, position.longitude),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _statusMessage = "Location updated successfully.";
      });
    } catch (e) {
      print("Firebase update error: $e");
      setState(() {
        _statusMessage = "Error sending location: $e";
      });
    }
  }

  void _startApiMonitoring() {
  _apiTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
    try {
      final response = await http.get(Uri.parse(
          'https://ruya-production.up.railway.app/api/status'));
      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);

        // Rename "model" to "mode" if present
        final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
        if (data.containsKey('model')) {
          data['mode'] = data['model'];
          data.remove('model');
        }

        await FirebaseFirestore.instance
            .collection('devices')
            .doc('deviceData1')
            .set(data);

        print("API data (with 'mode') updated to Firebase: $data");
      } else {
        print("Failed to fetch API: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching API: $e");
    }
  });
}


  @override
  void dispose() {
    _locationTimer?.cancel();
    _apiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Visually Impaired Mode")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTracking ? Icons.location_on : Icons.location_off,
              size: 80,
              color: _isTracking ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            Text(
              "User: ${blindUserId.replaceAll('_', ' ').toUpperCase()}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
