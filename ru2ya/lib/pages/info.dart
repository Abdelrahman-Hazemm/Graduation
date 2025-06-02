import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('blind_users')
        .doc('blind_user_1')
        .get();
    setState(() {
      userData = doc.data();
      isLoading = false;
    });
  }

  String getDisplayString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is DocumentReference) return value.path;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0075f9),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userData == null
          ? Center(child: Text('No data found'))
          : buildUserInfo(context),
    );
  }

  Widget buildUserInfo(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Color(0xFF0075f9),
          width: double.infinity,
          height: double.infinity,
        ),
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height - 100,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
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
                          color: Color(0xFF0075f9),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    buildInfoField('Name', getDisplayString(userData?['name'])),
                    buildInfoField('Phone Number',
                        getDisplayString(userData?['phoneNumber'])),
                    buildInfoField('Date Of Birth',
                        getDisplayString(userData?['dateOfBirth'])),
                    buildInfoField(
                        'Gender', getDisplayString(userData?['gender'])),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF0075f9),
          ),
        ),
        SizedBox(height: 20.0),
        Text(
          value,
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        SizedBox(height: 10.0),
        Divider(thickness: 1, color: Colors.black),
      ],
    );
  }
}
