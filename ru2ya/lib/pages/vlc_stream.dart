import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';

class VlcStreamPage extends StatelessWidget {
  final String rtmpUrl = 'rtmp://trolley.proxy.rlwy.net:24127/stream';

  Future<void> _launchVlc(BuildContext context) async {
    try {
      final intent = AndroidIntent(
        action: 'action_view',
        data: rtmpUrl,
        package: 'org.videolan.vlc', // VLC package name
      );

      await intent.launch();
      debugPrint('Intent launched successfully');
    } catch (e) {
      debugPrint('Failed to launch VLC: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch VLC: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Open Stream in VLC')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _launchVlc(context),
          child: Text('Open Stream in VLC'),
        ),
      ),
    );
  }
}