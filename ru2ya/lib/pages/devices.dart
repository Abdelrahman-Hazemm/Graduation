import 'package:flutter/material.dart';
import 'package:ru2ya/pages/caregiver.dart';
import 'package:ru2ya/pages/details.dart';
import 'package:ru2ya/pages/welcome.dart';

class Devices extends StatelessWidget {
  final List<Map<String, String>> devices = [
    {"name": "Glasses 1", "date": "May 30th, 2003", "status": "Paired"},
    {"name": "Glasses 2", "date": "May 3rd, 2025", "status": "Paired"},
    {"name": "Glasses 3", "date": "May 2nd, 2025", "status": "Reconnect"},
    {"name": "Glasses 4", "date": "May 1st, 2025", "status": "Reconnect"},
    {"name": "Glasses 5", "date": "April 1st, 2024", "status": "Paired"},
  ];

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
      body: ListView(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const Details()));
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
                              child:
                                  Image.asset('assets/glasses.png', width: 40),
                            ),
                          ),
                          title: Text(
                            device["name"]!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF0075f9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            device["date"]!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Text(
                            device["status"]!,
                            style: TextStyle(
                              color: device["status"] == "Reconnect"
                                  ? Colors.red
                                  : Colors.green,
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
          const SizedBox(height: 100),
          Center(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const Caregiver(),
                ));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 27.0, vertical: 5.0),
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
          ),
        ],
      ),
    );
  }
}
