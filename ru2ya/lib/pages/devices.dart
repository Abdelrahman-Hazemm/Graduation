import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ru2ya/pages/caregiver.dart';
import 'package:ru2ya/pages/details.dart';
import 'package:ru2ya/pages/welcome.dart';

class Devices extends StatefulWidget {
  @override
  _DevicesState createState() => _DevicesState();
}

class _DevicesState extends State<Devices> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String caregiverId = "caregiver_1";
  List<Map<String, dynamic>> devices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use StreamBuilder to listen for real-time updates
  }

  // Stream to listen to caregiver's assigned blind users and devices
  Stream<List<Map<String, dynamic>>> _getDeviceStream() {
    return _firestore
        .collection('caregivers')
        .doc(caregiverId)
        .snapshots()
        .asyncMap((caregiverDoc) async {
      List<Map<String, dynamic>> devices = [];

      if (caregiverDoc.exists) {
        Map<String, dynamic> caregiverData =
            caregiverDoc.data() as Map<String, dynamic>;

        if (caregiverData.containsKey('assignedBlindUsers')) {
          dynamic assignedUser = caregiverData['assignedBlindUsers'];

          if (assignedUser is DocumentReference) {
            DocumentSnapshot blindUserDoc = await assignedUser.get();
            if (blindUserDoc.exists) {
              Map<String, dynamic> userData =
                  blindUserDoc.data() as Map<String, dynamic>;

              if (userData.containsKey('assignedDevice')) {
                DocumentReference deviceRef = userData['assignedDevice'];
                DocumentSnapshot deviceDoc = await deviceRef.get();

                if (deviceDoc.exists) {
                  Map<String, dynamic> deviceData =
                      deviceDoc.data() as Map<String, dynamic>;

                  bool wifiConnected = deviceData['wifiConnected'] == true;

                  devices.add({
                    "id": deviceDoc.id,
                    "mode": deviceData['mode'] ?? 'No mode set',
                    "userName": userData['name'] ?? 'Unknown User',
                    "status": wifiConnected ? "Connected" : "Disconnected",
                    "wifiConnected": wifiConnected,
                    "battery": deviceData['battery'] ?? 'N/A',
                    "temperature": deviceData['temperature'] ?? 'N/A',
                    "lastUpdated":
                        deviceData['timestamp']?.toString() ?? 'Unknown',
                    "blindUserData": {
                      ...userData,
                      "id": blindUserDoc.id,
                    },
                  });
                }
              }
            }
          }
        }
      }
      return devices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const Welcome(),
              ),
            );
          },
          icon: Image.asset(
            'assets/arrow-left.png',
            width: 35,
            height: 35,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getDeviceStream(), // Stream listens for real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No devices paired",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAddGlassesButton(context),
                ],
              ),
            );
          }

          devices = snapshot.data!;

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 0.0),
                    const Text(
                      "PAIRED DEVICES",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...devices.map(
                      (device) => Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => Details(
                                    blindUserData: device["blindUserData"],
                                    deviceData: device,
                                  ),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFF0075f9),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset('assets/glasses.png',
                                      width: 40),
                                ),
                              ),
                              title: Text(
                                "Assigned to: ${device["userName"]}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF0075f9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Battery: ${device["battery"]} | Temp: ${device["temperature"]}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    device["lastUpdated"],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                device["status"],
                                style: TextStyle(
                                  color: device["status"] == "Connected"
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.0,
                                ),
                              ),
                            ),
                          ),
                          const Divider(
                            color: Colors.grey,
                            thickness: 2,
                            height: 10.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildAddGlassesButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddGlassesButton(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Optional Lottie animation or Icon
                      const Icon(Icons.construction, size: 60,  color: Color(0xFF0075f9),),
                      const SizedBox(height: 20),
                      const Text(
                        "Coming Soon!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "We're working on this feature. It will be available in a future update!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor:   const Color(0xFF0075f9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Got it",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 27.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0075f9),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/glasses.png',
                width: 60.0,
                color: Colors.white70,
                height: 60.0,
              ),
              const SizedBox(width: 20.0),
              const Text(
                'ADD NEW GLASSES ',
                style: TextStyle(
                  color: Colors
                      .white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
