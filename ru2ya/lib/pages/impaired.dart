import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImpairedPage extends StatefulWidget {
  const ImpairedPage({Key? key}) : super(key: key);

  @override
  State<ImpairedPage> createState() => _ImpairedPageState();
}

class _ImpairedPageState extends State<ImpairedPage> {
  final String blindUserId = "blind_user_1"; // Matches your Firebase structure
  late StreamSubscription<Position> _positionStreamSubscription;
  bool _isTracking = false;
  String _statusMessage = "Initializing location tracking...";

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  // Start tracking the location and sending updates to Firebase
  Future<void> _initLocationTracking() async {
    bool permissionGranted = await _checkLocationPermission();
    if (permissionGranted) {
      _startLocationUpdates();
    }
  }

  // Check and request permission if necessary
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage =
            "Location services are disabled. Please enable them in settings.";
      });
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = "Location permission denied.";
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage =
            "Location permissions are permanently denied. Please enable them in app settings.";
      });
      return false;
    }

    return true;
  }

  // Start listening to location updates
  void _startLocationUpdates() {
    setState(() {
      _isTracking = true;
      _statusMessage = "Tracking and sending your location...";
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update location every 10 meters
      ),
    ).listen((Position position) {
      _sendLocationToFirebase(position);
    });
  }

  // Send the location data to Firebase using the structure from the images
  Future<void> _sendLocationToFirebase(Position position) async {
    try {
      // Reference to the document
      final DocumentReference docRef =
          FirebaseFirestore.instance.collection('blind_users').doc(blindUserId);

      // Get the document
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Update only location and timestamp if document exists
        await docRef.update({
          'location': GeoPoint(position.latitude, position.longitude),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print("Location updated for existing user");
      } else {
        // Create new document if it doesn't exist
        print("Creating new user document");
        await docRef.set({
          'name': 'Jane',
          'assignedCaregivers': ['caregiver_1'],
          'location': GeoPoint(position.latitude, position.longitude),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _statusMessage = "Location updated successfully";
      });
    } catch (e) {
      print("Error sending location: $e");
      setState(() {
        _statusMessage = "Error sending location: $e";
      });
    }
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    if (_isTracking) {
      _positionStreamSubscription.cancel();
    }
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
