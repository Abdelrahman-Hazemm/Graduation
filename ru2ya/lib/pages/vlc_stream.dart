import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:http/http.dart' as http;

class VlcStreamPage extends StatefulWidget {
  @override
  _VlcStreamPageState createState() => _VlcStreamPageState();
}

class _VlcStreamPageState extends State<VlcStreamPage> {
  final String requestId = 'glasses01';
  final String fetchStreamUrlEndpoint =
      'https://ruya-production.up.railway.app/api/stream/get-stream-url?deviceId=glasses01';

  StreamSubscription<DocumentSnapshot>? _subscription;
  Timer? _timeoutTimer;
  bool _isStreaming = false;
  String? _fullStreamUrl;

  Future<void> _sendRequest() async {
    final requestRef =
        FirebaseFirestore.instance.collection('requests').doc(requestId);

    final doc = await requestRef.get();
    if (doc.exists &&
        doc.data() is Map &&
        (doc.data() as Map)['status'] == 'pending') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hourglass_top,
                    color: Colors.orangeAccent,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please Wait',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Request already pending. Please wait for it to be processed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    label: const Text('OK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      return;
    }

    await requestRef.set({
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'stream': true,
    });

    _waitForResponse(requestRef);
  }

  void _waitForResponse(DocumentReference requestRef) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Waiting for Raspberry Pi response...')),
    );

    _subscription = requestRef.snapshots().listen((snapshot) async {
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return;

      final status = data['status'];
      if (status == 'accepted') {
        print("Request accepted by Pi.");
        _cancelTimeout();
        await _fetchStreamUrlAndLaunch();
        // Cancel subscription after successfully starting the stream
        _subscription?.cancel();
        _subscription = null;
      } else if (status == 'rejected') {
        _cancelTimeout();
        // Cancel subscription since request is finished
        _subscription?.cancel();
        _subscription = null;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cancel,
                      color: Colors.redAccent,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Request Rejected',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The Raspberry Pi has rejected your request.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (status == 'timeout') {
        _cancelTimeout();
        // Cancel subscription since request is finished
        _subscription?.cancel();
        _subscription = null;
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
    _timeoutTimer = null;
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _fetchStreamUrlAndLaunch() async {
    try {
      final response = await http.get(Uri.parse(fetchStreamUrlEndpoint));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _fullStreamUrl = data['streamUrl'];
        print('Fetched stream URL: $_fullStreamUrl');

        if (_fullStreamUrl != null && _fullStreamUrl!.isNotEmpty) {
          setState(() => _isStreaming = true);
          _launchVlc();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Empty stream URL received.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get stream URL.')),
        );
      }
    } catch (e) {
      debugPrint('Fetch stream URL error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching stream URL: $e')),
      );
    }
  }

  Future<void> _launchVlc() async {
    if (_fullStreamUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No stream URL found.')),
      );
      return;
    }

    try {
      final intent = AndroidIntent(
        action: 'action_view',
        data: _fullStreamUrl,
        package: 'org.videolan.vlc',
      );
      print('Launching VLC with URL: $_fullStreamUrl');
      await intent.launch();
    } catch (e) {
      debugPrint('Failed to launch VLC: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch VLC: $e')),
      );
    }
  }

  Future<void> _stopStream() async {
    const stopUrl =
        'https://ruya-production.up.railway.app/api/stream/stop-stream';

    // Cancel any active subscriptions and timers first
    _cancelTimeout();

    try {
      final response = await http.post(Uri.parse(stopUrl));

      if (response.statusCode == 200) {
        // Also clean up the Firestore document to avoid any lingering status
        try {
          final requestRef =
              FirebaseFirestore.instance.collection('requests').doc(requestId);
          await requestRef.update({'status': 'stopped'});
        } catch (e) {
          debugPrint('Error updating Firestore document: $e');
        }

        setState(() {
          _isStreaming = false;
          _fullStreamUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stream stopped successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to stop stream. Status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping stream: $e')),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _sendRequest,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
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
            const SizedBox(height: 20),
            InkWell(
              onTap: _stopStream,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text(
                  'Stop Stream',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
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
