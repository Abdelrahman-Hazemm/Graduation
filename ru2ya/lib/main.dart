import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ru2ya/pages/Start.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ru2ya/pages/welcome.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ru2ya/pages/vlc_stream.dart'; // Import VlcStreamPage

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    final notification = message.notification!;
    final android = message.notification?.android;
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_default_channel',
          'FCM Notifications',
          channelDescription: 'Channel for FCM notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize flutter_local_notifications with onDidReceiveNotificationResponse
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload == 'open_vlc_stream') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => VlcStreamPage()),
        );
      }
    },
  );

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

  // Retrieve and print the device token
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  messaging.getToken().then((token) {
    if (token != null) {
      print('Device Token: $token');
    }
  });

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: \\${message.data}');
    if (message.notification != null) {
      final notification = message.notification!;
      final android = message.notification?.android;
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_default_channel',
            'FCM Notifications',
            channelDescription: 'Channel for FCM notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
        ),
        payload: 'open_vlc_stream', // Pass payload to open VLC stream page
      );
    }
  });

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
        navigatorKey: navigatorKey, // Add this line
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Inter'),
        home: Welcome());
  }
}