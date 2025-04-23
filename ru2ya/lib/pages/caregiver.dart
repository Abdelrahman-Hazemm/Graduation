import 'package:flutter/material.dart';
import 'package:ru2ya/pages/devices.dart';

class Caregiver extends StatelessWidget {
  const Caregiver({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Devices(),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 0.0),
              const Text(
                'Scan Your QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0075f9),
                ),
              ),
              const SizedBox(height: 40.0),
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/QR.png', width: 270),
                  Positioned(
                    top: 60,
                    child: Image.asset('assets/Group.png', height: 210),
                  ),
                ],
              ),
              const SizedBox(height: 40.0),
              const Text(
                'OR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Color(0xFF0075f9),
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Add New Glasses ID',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  color: Color(0xFF0075f9),
                ),
              ),
              const SizedBox(height: 30.0),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      'assets/glasses.png',
                      height: 24.0,
                      width: 24.0,
                      color: Colors.black,
                    ),
                  ),
                  labelText: 'Glasses ID',
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Color(0xFFA6A6A6),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30.0),
              InkWell(
                onTap: () {
                  // Navigator.of(context).push(MaterialPageRoute(
                  //   builder: (context) => const Welcome(),
                  // ));
                },
                borderRadius: BorderRadius.circular(15.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  width: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0075f9),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'ADD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }
}
