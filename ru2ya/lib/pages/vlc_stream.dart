import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:android_intent_plus/android_intent.dart';

class VlcStreamPage extends StatefulWidget {
  @override
  _VlcStreamPageState createState() => _VlcStreamPageState();
}

class _VlcStreamPageState extends State<VlcStreamPage> {
  final String requestId = 'streamRequest1'; // You can make this dynamic (e.g., user ID)
  final String rtmpUrl = 'rtmp://trolley.proxy.rlwy.net:24127/stream';

  StreamSubscription<DocumentSnapshot>? _subscription;
  Timer? _timeoutTimer;

  Future<void> _sendRequest() async {
    final requestRef = FirebaseFirestore.instance.collection('requests').doc(requestId);

    final doc = await requestRef.get();
    if (doc.exists && doc.data() is Map && (doc.data() as Map)['status'] == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request already pending. Please wait.')),
      );
      return;
    }

    await requestRef.set({
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'streamUrl': rtmpUrl,
    });

    _waitForResponse(requestRef);
  }

  void _waitForResponse(DocumentReference requestRef) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Waiting for Raspberry Pi response...')),
    );

    _subscription = requestRef.snapshots().listen((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return;

      final status = data['status'];

      if (status == 'accepted') {
        _cancelTimeout();
        _launchVlc();
      } else if (status == 'rejected') {
        _cancelTimeout();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request rejected by Pi.')),
        );
      } else if (status == 'timeout') {
        _cancelTimeout();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request timed out.')),
        );
      }
    });

    _timeoutTimer = Timer(Duration(seconds: 30), () async {
      try {
        final latest = await requestRef.get();
        final data = latest.data() as Map<String, dynamic>?;

        if (data != null && data['status'] == 'pending') {
          await requestRef.update({'status': 'timeout'});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request timed out.')),
          );
        }
      } catch (e) {
        debugPrint('Timeout update error: $e');
      } finally {
        _subscription?.cancel();
      }
    });
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _subscription?.cancel();
  }

  Future<void> _launchVlc() async {
    try {
      final intent = AndroidIntent(
        action: 'action_view',
        data: rtmpUrl,
        package: 'org.videolan.vlc',
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Failed to launch VLC: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch VLC: $e')),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stream Request')),
      body: Center(
        child: InkWell(
          onTap: _sendRequest,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Text(
              'Request Stream',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
