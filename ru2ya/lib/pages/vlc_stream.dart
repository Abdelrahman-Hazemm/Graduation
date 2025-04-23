import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VlcStreamPage extends StatelessWidget {
  // RTMP URL for the stream
  final String rtmpUrl = 'rtmp://trolley.proxy.rlwy.net:24127/stream';

  // Function to launch VLC with the RTMP stream URL
  Future<void> _launchVlc(BuildContext context) async {
    final Uri vlcUri = Uri.parse('vlc://$rtmpUrl');  // Use Uri.parse for the VLC URL

    // Check if VLC can handle the URL using canLaunchUrl
    if (await canLaunchUrl(vlcUri)) {
      await launchUrl(vlcUri);
    } else {
      // Handle the case where VLC cannot be launched
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open VLC or stream URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Open Stream in VLC'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _launchVlc(context),  // Pass context here
          child: Text('Open Stream in VLC'),
        ),
      ),
    );
  }
}
