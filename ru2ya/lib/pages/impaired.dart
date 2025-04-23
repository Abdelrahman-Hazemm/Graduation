import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class ImpairedPage extends StatefulWidget {
  const ImpairedPage({Key? key}) : super(key: key);

  @override
  State<ImpairedPage> createState() => _ImpairedPageState();
}

class _ImpairedPageState extends State<ImpairedPage> {
  final String blindUserId = "blind_user_1";
  StreamSubscription<Position>? _positionStreamSubscription;
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
    if (_positionStreamSubscription != null) return;

    setState(() {
      _isTracking = true;
      _statusMessage = "Tracking and sending your location...";
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) => _sendLocationToFirebase(position),
      onError: (error) {
        print("Location stream error: $error");
        setState(() {
          _statusMessage = "Location stream error: $error";
        });
      },
    );
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

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
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
