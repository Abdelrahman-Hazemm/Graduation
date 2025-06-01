import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ru2ya/pages/info.dart';
import 'package:ru2ya/pages/vlc_stream.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class Details extends StatefulWidget {
  final Map<String, dynamic> blindUserData;
  final Map<String, dynamic> deviceData;

  const Details({
    Key? key,
    required this.blindUserData,
    required this.deviceData,
  }) : super(key: key);

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  GoogleMapController? _mapController;
  late LatLng _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoadingLocation = false;
  StreamSubscription<DocumentSnapshot>? _locationSubscription;
  StreamSubscription<DocumentSnapshot>? _deviceSubscription;
  Timer? _apiTimer;
  late String blindUserId;
  late String deviceId;
  String currentMode = "Loading...";
  String batteryLevel = "Loading...";
  bool isDeviceConnected = false; // Will store wifiConnected status
  bool isApiConnected = true; // Track API connection status
  DateTime? lastApiResponse;
  @override
  void initState() {
    super.initState();
    blindUserId = widget.blindUserData['id'] ?? "blind_user_1";
    deviceId = widget.deviceData['id'] ?? "device_1";
    currentMode = widget.deviceData['mode'] ?? "No mode set";
    batteryLevel = widget.deviceData['battery'] ?? "N/A";
    // Use wifiConnected status instead of ip
    isDeviceConnected = widget.deviceData['status'] == "Connected";
    _initializePosition();
    _listenToBlindUserLocation();
    _listenToDeviceUpdates();
    _startApiMonitoring(); // Start API monitoring
  }

  void _initializePosition() {
    final location = widget.blindUserData['location'] as GeoPoint?;
    _currentPosition = location != null
        ? LatLng(location.latitude, location.longitude)
        : const LatLng(30.0603153, 30.9498286);
    _updateMarkers();
  }

  void _listenToDeviceUpdates() {
    _deviceSubscription = FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            currentMode = data['mode'] ?? "No mode set";
            batteryLevel = data['battery'] ?? "N/A";
            // Use wifiConnected status instead of ip
            isDeviceConnected = data['wifiConnected'] == true;
          });
        }
      }
    }, onError: (error) {
      print("Error listening to device updates: $error");
      if (mounted) {
        setState(() {
          currentMode = "Error loading data";
          batteryLevel = "Error";
          isDeviceConnected = false; // Default to disconnected on error
        });
      }
    });  }

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

          if (mounted) {
            setState(() {
              isApiConnected = true;
              lastApiResponse = DateTime.now();
            });
          }

          print("API data (with 'mode') updated to Firebase: $data");
        } else {
          if (mounted) {
            setState(() {
              isApiConnected = false;
            });
          }
          print("Failed to fetch API: ${response.statusCode}");
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isApiConnected = false;
          });
        }
        print("Error fetching API: $e");
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _deviceSubscription?.cancel();
    _apiTimer?.cancel();
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
        infoWindow:
            InfoWindow(title: widget.blindUserData['name'] ?? 'Blind User'),
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
    final userName = widget.blindUserData['name'] ?? 'Unknown User';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),
        ),
        title: Text(
          userName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info, color: Colors.blue, size: 30),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Info()),
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
                          onMapCreated: (controller) {
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
                                Text(
                                  "Tracking $userName",
                                  style: const TextStyle(
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
                _buildModeTile(),
                const SizedBox(height: 25),
                _buildActionTile(
                    "My Glasses", "assets/glasses.png", const Color(0xFF0075f9),
                    () {
                  // Add navigation to glasses management page when implemented
                }),
                const SizedBox(height: 25),
                _buildActionTile(
                    "Live Feed", "assets/visible.png", const Color(0xFF0075f9),
                    () {
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
    // Determine overall connection status based on both device and API
    bool overallConnected = isDeviceConnected && isApiConnected;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: overallConnected ? const Color(0xFF4ACD12) : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overallConnected ? "CONNECTED" : "DISCONNECTED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Battery: $batteryLevel",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  batteryLevel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Status indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDeviceConnected ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isDeviceConnected ? "Device Online" : "Device Offline",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTile() {
    return InkWell(
      onTap: () {
        // Could open a modal to change the mode in the future
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4ACD12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/object.png',
              width: 55,
              height: 55,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 40.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CURRENT MODE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currentMode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
      String title, String asset, Color color, Function() onTap) {
    return InkWell(
      onTap: onTap,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
