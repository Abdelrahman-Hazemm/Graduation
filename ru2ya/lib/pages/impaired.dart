import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ru2ya/pages/qr_connection.dart';

class ImpairedPage extends StatefulWidget {
  const ImpairedPage({Key? key}) : super(key: key);

  @override
  State<ImpairedPage> createState() => _ImpairedPageState();
}

class _ImpairedPageState extends State<ImpairedPage> {
  final String blindUserId = "blind_user_1";
  Timer? _locationTimer;
  bool _isTracking = false;
  String _statusMessage = "Initializing location tracking...";
  @override
  void initState() {
    super.initState();
    _initLocationTracking();
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
    }  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
            ),            const SizedBox(height: 40),
            Text(
              "User: ${blindUserId.replaceAll('_', ' ').toUpperCase()}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // Generate QR Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WifiQrGeneratorPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 13.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0075f9),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/qrr.png',
                        width: 50.0,
                        color: Colors.white,
                        height: 50.0,
                      ),
                      const SizedBox(width: 25.0),
                      const Text(
                        'GENERATE QR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
