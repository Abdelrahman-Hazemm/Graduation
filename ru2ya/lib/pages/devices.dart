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
    _fetchPairedDevices();
  }

  Future<void> _fetchPairedDevices() async {
    setState(() {
      isLoading = true;
      devices = [];
    });

    try {
      // Fetch caregiver document
      DocumentSnapshot caregiverDoc =
          await _firestore.collection('caregivers').doc(caregiverId).get();

      if (caregiverDoc.exists) {
        Map<String, dynamic> caregiverData =
            caregiverDoc.data() as Map<String, dynamic>;

        // Get assignedBlindUsers reference
        DocumentReference? blindUserRef;
        if (caregiverData.containsKey('assignedBlindUsers')) {
          dynamic assignedUser = caregiverData['assignedBlindUsers'];
          if (assignedUser is DocumentReference) {
            blindUserRef = assignedUser;
          }
        }

        if (blindUserRef != null) {
          // Fetch the blind user's assigned device
          DocumentSnapshot blindUserDoc = await blindUserRef.get();
          if (blindUserDoc.exists) {
            Map<String, dynamic> userData =
                blindUserDoc.data() as Map<String, dynamic>;

            // Get device reference from blind user
            DocumentReference? deviceRef;
            if (userData.containsKey('assignedDevice')) {
              deviceRef = userData['assignedDevice'];
            }

            if (deviceRef != null) {
              DocumentSnapshot deviceDoc = await deviceRef.get();
              if (deviceDoc.exists) {
                Map<String, dynamic> deviceData =
                    deviceDoc.data() as Map<String, dynamic>;

                devices.add({
                  "id": deviceDoc.id,
                  "name": deviceData['model'] ?? 'Unnamed Device',
                  "userName": userData['name'] ?? 'Unknown User',
                  "status": deviceData['wifiConnected']
                      ? "Connected"
                      : "Disconnected",
                  "battery": deviceData['battery'] ?? 'N/A',
                  "temperature": deviceData['temperature'] ?? 'N/A',
                  "lastUpdated":
                      deviceData['timestamp']?.toString() ?? 'Unknown',
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching devices: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
              ? Center(
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
                      SizedBox(height: 20),
                      _buildAddGlassesButton(context),
                    ],
                  ),
                )
              : ListView(
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
                                            builder: (context) => Details()));
                                  },
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: const Color(0xFF0075f9),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.asset('assets/glasses.png',
                                            width: 40),
                                      ),
                                    ),
                                    title: Text(
                                      device["name"],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF0075f9),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Assigned to: ${device["userName"]}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          "Battery: ${device["battery"]} | Temp: ${device["temperature"]}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          device["lastUpdated"],
                                          style: const TextStyle(
                                              color: Colors.grey),
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
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAddGlassesButton(context),
                  ],
                ),
    );
  }

  Widget _buildAddGlassesButton(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const Caregiver(),
          ));
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
                height: 60.0,
              ),
              const SizedBox(width: 20.0),
              const Text(
                'ADD NEW GLASSES',
                style: TextStyle(
                  color: Colors.white,
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
