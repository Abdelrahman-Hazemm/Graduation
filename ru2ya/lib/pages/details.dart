import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ru2ya/pages/devices.dart';
import 'package:ru2ya/pages/info.dart';
import 'package:ru2ya/pages/vlc_stream.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Details extends StatefulWidget {
  const Details({super.key});

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(30.0603153, 30.9498286);
  Set<Marker> _markers = {};
  bool _isLoadingLocation = false;
  StreamSubscription<DocumentSnapshot>? _locationSubscription;
  final String blindUserId = "blind_user_1";

  @override
  void initState() {
    super.initState();
    _listenToBlindUserLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _listenToBlindUserLocation() {
    _locationSubscription = FirebaseFirestore.instance
        .collection('blind_users')
        .doc(blindUserId)
        .snapshots()
        .listen((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;

        if (data.containsKey('location')) {
          GeoPoint geoPoint = data['location'] as GeoPoint;
          if (mounted) {
            setState(() {
              _currentPosition = LatLng(geoPoint.latitude, geoPoint.longitude);
              _updateMarkers();
            });

            if (_mapController != null) {
              _mapController!
                  .animateCamera(CameraUpdate.newLatLng(_currentPosition));
            }
          }
        }
      }
    }, onError: (error) {
      print("Error listening to location: $error");
    });
  }

  Future<void> _fetchLatestLocation() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('blind_users')
          .doc(blindUserId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('location')) {
          GeoPoint geoPoint = data['location'] as GeoPoint;
          setState(() {
            _currentPosition = LatLng(geoPoint.latitude, geoPoint.longitude);
            _updateMarkers();
          });

          if (_mapController != null) {
            _mapController!
                .animateCamera(CameraUpdate.newLatLng(_currentPosition));
          }
        }
      }
    } catch (e) {
      print("Failed to fetch location manually: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching location: $e")),
        );
      }
    }
  }

  void _updateMarkers() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: MarkerId(blindUserId),
        position: _currentPosition,
        infoWindow: const InfoWindow(title: "Blind User"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _getUserLocation() async {
    if (_isLoadingLocation) return;
    _isLoadingLocation = true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enable location services")),
        );
      }
      _isLoadingLocation = false;
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions denied")),
          );
        }
        _isLoadingLocation = false;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Location permissions permanently denied")),
        );
      }
      _isLoadingLocation = false;
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId("caregiver_location"),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: const InfoWindow(title: "Your Location"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          );
        });
      }

      if (_mapController != null && mounted) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude), 15.0));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get location: $e")),
        );
      }
    }

    _isLoadingLocation = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => Devices()),
            );
          },
          icon: Image.asset(
            'assets/arrow-left.png',
            width: 35,
            height: 35,
            color: Colors.black,
          ),
        ),
        actions: [
          SizedBox(
            width: 60,
            height: 60,
            child: IconButton(
              icon: const Icon(Icons.info, color: Colors.blue, size: 35),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Info()),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentPosition,
                            zoom: 15,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            _updateMarkers();
                          },
                          myLocationEnabled: true,
                          markers: _markers,
                          zoomControlsEnabled: false,
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.green),
                                  onPressed: _fetchLatestLocation,
                                ),
                              ),
                              const SizedBox(height: 10),
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(Icons.my_location,
                                      color: Colors.blue),
                                  onPressed: _getUserLocation,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_pin_circle,
                                    color: Colors.red),
                                const SizedBox(width: 8),
                                const Text(
                                  "Tracking Blind User",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildStatusCard(),
                const SizedBox(height: 25),
                _buildActionTile("OBJECT\nDETECTION MODE", "assets/object.png",
                    const Color(0xFF4ACD12), () {}),
                const SizedBox(height: 25),
                _buildActionTile("My Glasses", "assets/glasses.png",
                    const Color(0xFF0075f9), () {}),
                const SizedBox(height: 25),
                _buildActionTile("Live Feed", "assets/visible.png",
                    const Color(0xFF0075f9), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VlcStreamPage()),
                  );
                }),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF4ACD12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CONNECTED",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "8hr Remaining",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              "80%",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String asset, Color color, Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Material(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                asset,
                width: 55,
                height: 55,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 40.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
