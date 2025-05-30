import 'package:flutter/material.dart';
import 'package:ru2ya/pages/welcome.dart';

class Start extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0075F9),
      body: Column(
        children: [
          const SizedBox(height: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/glasses.png',
                width: 70,
                height: 70,
              ),
              const SizedBox(width: 10),
              const Text(
                "RU'YA",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vector Image
                Image.asset(
                  'assets/Vector.png',
                  width: 450,
                  height: 450,
                  fit: BoxFit.cover,
                ),
                const Positioned(
                  top: 160,
                  child: Text(
                    "Let's Get",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Positioned(
                  top: 230,
                  child: Text(
                    "Started!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 70,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const Welcome(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              alignment: Alignment.center,
              width: 250,
              child: const Text(
                'START NOW',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 25.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80.0),
        ],
      ),
    );
  }
}
