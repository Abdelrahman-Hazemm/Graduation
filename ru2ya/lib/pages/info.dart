import 'package:flutter/material.dart';

class Info extends StatelessWidget {
  const Info({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/arrow-left.png',
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // Blue Background
          Container(
            color: Colors.blue,
            width: double.infinity,
            height: double.infinity,
          ),

          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height - 100, // Remaining height
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), // Circular edges
                  topRight: Radius.circular(30),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20), // General padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        "Personal Information",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ),
                    SizedBox(height: 40),

                    Padding(
                      padding: EdgeInsets.only(left: 10), // Added left padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 20.0),
                          Text('Bn7eb Amr Ashraf',style: TextStyle(color: Colors.black54),),
                          SizedBox(height: 10.0),
                        ],
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.black),

                    Padding(
                      padding: EdgeInsets.only(left: 10), // Added left padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.0),
                          Text(
                            'Glass ID',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 20.0),
                          Text('#001',style: TextStyle(color: Colors.black54),),
                          SizedBox(height: 10.0),
                        ],
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.black),

                    /// **Phone Number Section**
                    Padding(
                      padding: EdgeInsets.only(left: 10), // Added left padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.0),
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 20.0),
                          Text('01068812354',style: TextStyle(color: Colors.black54),),
                          SizedBox(height: 10.0),
                        ],
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.black),

                    /// **Date of Birth Section**
                    Padding(
                      padding: EdgeInsets.only(left: 10), // Added left padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.0),
                          Text(
                            'Date Of Birth',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 20.0),
                          Text('30 May 2003',style: TextStyle(color: Colors.black54),),
                          SizedBox(height: 10.0),
                        ],
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.black),

                    /// **Gender Section**
                    Padding(
                      padding: EdgeInsets.only(left: 10), // Added left padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.0),
                          Text(
                            'Gender',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 20.0),
                          Text('Male',style: TextStyle(color: Colors.black54),),
                          SizedBox(height: 10.0),
                        ],
                      ),
                    ),
                    Divider(thickness: 1, color: Colors.black),
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
