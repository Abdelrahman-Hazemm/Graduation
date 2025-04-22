import 'package:flutter/material.dart';

class Caregiver extends StatelessWidget {
  const Caregiver({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 150.0),
            const Text(
              'Scan Your QR Code',
              style: TextStyle(
                fontSize: 35.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0075f9),
              ),
            ),
            const SizedBox(height: 50.0),
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
            const SizedBox(height: 40),
            const Text(
              'OR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: Color(0xFF0075f9),
              ),
            ),
            const Text(
              'Add New Glasses ID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 27,
                color: Color(0xFF0075f9),
              ),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      'assets/glasses.png',
                      height: 24.0,
                      color: Colors.black,
                      width: 24.0,
                    ),
                  ),
                  labelText: 'Glasses ID',
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
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
            ),
            const SizedBox(height: 20.0),
            InkWell(
              onTap: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (context) =>const Welcome(),),);
              },
              borderRadius: BorderRadius.circular(15.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0075f9),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                alignment: Alignment.center,
                width: 250,
                child: const Text(
                  'ADD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 25.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
