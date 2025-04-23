import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Optional for map

class DetailsPage extends StatelessWidget {
  final String blindUserId = "blind_user_1";

  DetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DocumentReference userDoc =
        FirebaseFirestore.instance.collection('blind_users').doc(blindUserId);

    return Scaffold(
      appBar: AppBar(title: const Text("User Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final location = data['location'] as GeoPoint?;
          final lastUpdated = data['lastUpdated']?.toDate();

          if (location == null) {
            return const Center(child: Text("Location not available"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "Blind User Location",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text("Latitude: ${location.latitude}"),
                Text("Longitude: ${location.longitude}"),
                const SizedBox(height: 20),
                if (lastUpdated != null)
                  Text("Last Updated: ${lastUpdated.toLocal()}"),
                const SizedBox(height: 30),
                // Optional: Map View
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(location.latitude, location.longitude),
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId('userLocation'),
                        position: LatLng(location.latitude, location.longitude),
                        infoWindow: const InfoWindow(title: "Blind User"),
                      )
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
