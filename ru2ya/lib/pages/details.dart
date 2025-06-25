import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ru2ya/pages/info.dart';
import 'package:ru2ya/pages/vlc_stream.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
  bool _sosActive = false;
  Timer? _sosMonitorTimer;

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
    _startSosMonitor();
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
    });
  }

  void _startApiMonitoring() {
    _apiTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      bool gotResponse = false;
      try {
        final response = await http.get(
            Uri.parse('https://ruya-production.up.railway.app/api/status'));
        if (response.statusCode == 200) {
          gotResponse = true;
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
          print("Failed to fetch API: \\${response.statusCode}");
        }
      } catch (e) {
        print("Error fetching API: $e");
      }
      // If no response or error, set isApiConnected to false
      if (!gotResponse && mounted) {
        setState(() {
          isApiConnected = false;
        });
      }
    });
  }

  void _startSosMonitor() {
    // Replace 'YOUR_API_URL' with the actual API endpoint when available
    const apiUrl = 'YOUR_API_URL';
    _sosMonitorTimer?.cancel();
    _sosMonitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // Assume the API returns { "sos": true } when SOS is active
          if (data is Map && data['sos'] == true) {
            if (!_sosActive && mounted) {
              setState(() {
                _sosActive = true;
              });
            }
          } else {
            if (_sosActive && mounted) {
              setState(() {
                _sosActive = false;
              });
            }
          }
        }
      } catch (e) {
        // Optionally handle errors
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _deviceSubscription?.cancel();
    _apiTimer?.cancel();
    _sosMonitorTimer?.cancel();
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
            icon:  Icon(Icons.info, color:Colors.blue.withOpacity(0.7), size: 30),
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: GoogleMap(
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
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20.0),
                                bottomRight: Radius.circular(20.0),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.map, color: Colors.blue),
                          label: const Text('Open in Google Maps'),
                          onPressed: () async {
                            final lat = _currentPosition.latitude;
                            final lng = _currentPosition.longitude;
                            final googleMapsUrl =
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                            if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                              await launchUrl(
                                Uri.parse(googleMapsUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open Google Maps.')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                _buildStatusCard(),
                const SizedBox(height: 25),
                _buildModeTile(),
                
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

    // Check if lastApiResponse is older than 1 minute
    if (lastApiResponse != null) {
      final now = DateTime.now();
      final difference = now.difference(lastApiResponse!);
      if (difference.inMinutes >= 1) {
        overallConnected = false;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            overallConnected ? Icons.check_circle : Icons.warning_rounded,
            color: overallConnected ? Colors.green : Colors.yellow[800],
            size: 55,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Battery: $batteryLevel",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        batteryLevel,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDeviceConnected ? Icons.wifi : Icons.wifi_off,
                            color: Colors.black,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isDeviceConnected
                                ? "Device Online"
                                : "Device Offline",
                            style: const TextStyle(
                              color: Colors.black,
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
          ),
        ],
      ),
    );
  }

  Widget _buildModeTile() {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.lightBlueAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            currentMode == "none"
                ? Icon(
                    Icons.warning_rounded,
                    color: Colors.yellow[800],
                    size: 55,
                  )
                : Image.asset(
                    'assets/object.png',
                    width: 55,
                    height: 55,
                    fit: BoxFit.contain,
                    color: Colors.black,
                  ),
            const SizedBox(width: 40.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CURRENT MODE",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currentMode,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
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
      String title, String asset, Color color, Function() onTap, {bool noIcon = false}) {
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
            if (!noIcon)
              Image.asset(
                asset,
                width: 55,
                height: 55,
                fit: BoxFit.contain,
              ),
            if (!noIcon) const SizedBox(width: 40.0),
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
