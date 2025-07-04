import 'package:flutter/material.dart';
import 'package:ru2ya/pages/devices.dart';
import 'package:ru2ya/pages/impaired.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: [

          const SizedBox(height:150),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Image.asset(
          //       'assets/glasses.png',
          //       width: 60,
          //       height: 60,
          //       color: Colors.black,
          //     ),
          //     const Text(
          //       "RU'YA",
          //       style: TextStyle(
          //         fontSize: 35,
          //         fontWeight: FontWeight.bold,
          //         color: Colors.black,
          //       ),
          //     ),
          //   ],
          // ),

          const Center(
            child:Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 50.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0075F9),
              ),
            ),
          ),
          const SizedBox(height: 100.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Devices(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 13.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0075f9),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/caregiver.png',
                      width: 50.0,
                      height: 50.0,
                    ),
                    const SizedBox(width: 25.0),
                    const Text(
                      'CAREGIVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                    const SizedBox(width: 25.0),
                  ],
                ),
              ),
            ),
          ), //Caregiver
          const SizedBox(height: 30.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ImpairedPage(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30.0, vertical: 13.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0075f9),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/glasses.png',
                      width: 50.0,
                      height: 50.0,
                    ),
                    const SizedBox(width: 25.0),
                    const Text(
                      'IMPAIRED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                    const SizedBox(width: 25.0),

                  ],
                ),
              ),            ),
          ), //Impaired
          
        ],
      ),
    );
  }
}
