import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ru2ya/pages/Start.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Disable SSL verification (temporary fix for debugging)
  HttpOverrides.global = MyHttpOverrides();

  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  // Generate a custom token for the device
  const uuid = Uuid();
  String customToken = uuid.v4();
  print('Custom token: $customToken');

  // Log the device token
  String? firebaseToken = await FirebaseMessaging.instance.getToken();
  print('Firebase token: $firebaseToken');

  // Save the Firebase token to the user's document in Firestore
  const userId = 'user_123'; // Replace with the actual user ID
  if (firebaseToken != null) {
    try {
      await FirebaseFirestore.instance.collection('app_users').doc(userId).set({
        'deviceToken': firebaseToken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Firebase token saved to user document in Firestore');
    } catch (e) {
      print('Error saving token to user document: $e');
    }
  }

  runApp(ProviderScope(child: MyApp()));
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Inter'),
        home: Start());
  }
}