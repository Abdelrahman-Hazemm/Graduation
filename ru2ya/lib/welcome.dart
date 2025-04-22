import 'package:flutter/material.dart';
import 'package:ru2ya/devices.dart';


class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/glasses.png',
                width: 60,
                height: 60,
                color: Colors.black,
              ),
              const Text(
                "RU'YA",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 170.0),
          const Text(
            'Welcome!',
            style: TextStyle(
              fontSize: 60.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0075F9),
            ),
          ),
          const SizedBox(height:70.0),
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => Devices(),),);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0075f9),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/caregiver.png',
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
          const SizedBox(height:40.0),
          InkWell(
            onTap: () {
              // Navigator.of(context).push(MaterialPageRoute(
              //   builder: (context) =>const Welcome(),),);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30.0,vertical: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0075f9),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/glasses.png',
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
            ),
          ),
        ],
      ),
    );
  }
}
