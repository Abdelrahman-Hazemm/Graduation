import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ru2ya/pages/devices.dart';
import 'package:ru2ya/pages/info.dart';

class Details extends StatefulWidget {
  const Details({super.key});

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(30.0444, 31.2357);
  Set<Marker> _markers = {};
  bool _isLoadingLocation = false;

  @override
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
          _currentPosition = LatLng(position.latitude, position.longitude);
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId("user_location"),
              position: _currentPosition,
              infoWindow: const InfoWindow(title: "Your Location"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          );
        });
      }

      if (_mapController != null && mounted) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition));
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
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Devices(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.only(left: 10.0),
            child: Image.asset(
              'assets/arrow-left.png',
              width: 13.0,
              height: 13.0,
              color: Colors.black38,
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: 60,
            height: 60,
            child: IconButton(
              icon: const Icon(
                Icons.info,
                color: Colors.blue,
                size: 35,
              ),
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
                          },
                          myLocationEnabled: true,
                          markers: _markers,
                          zoomControlsEnabled: false,
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.my_location,
                                  color: Colors.blue),
                              onPressed: _getUserLocation,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Container(
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
                ),
                const SizedBox(height: 25),
                InkWell(
                  onTap: () {},
                  child: Material(
                    borderRadius: BorderRadius.circular(20),
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
                            "assets/object.png",
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 40.0),
                          const Text(
                            "OBJECT\nDETECTION MODE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                InkWell(
                  onTap: () {},
                  child: Material(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0075f9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/glasses.png",
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 40.0),
                          const Text(
                            "My Glasses",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                InkWell(
                  onTap: () {},
                  child: Material(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0075f9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/visible.png",
                            width: 55,
                            height: 55,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 57.0),
                          const Text(
                            "Live Feed",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
