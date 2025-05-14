import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WifiQrGeneratorPage extends StatefulWidget {
  const WifiQrGeneratorPage({super.key});

  @override
  State<WifiQrGeneratorPage> createState() => _WifiQrGeneratorPageState();
}

class _WifiQrGeneratorPageState extends State<WifiQrGeneratorPage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bluetoothController = TextEditingController();
  String _securityType = 'WPA2';

  @override
  void initState() {
    super.initState();
    _fetchDeviceInfo();
  }

  Future<void> _fetchDeviceInfo() async {
    await Permission.location.request();

    final info = NetworkInfo();
    final ssid = await info.getWifiName();

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final model = androidInfo.model ?? "UnknownDevice";
    final bluetoothName = "MyPiBridge_$model";

    setState(() {
      _ssidController.text = ssid?.replaceAll('"', '') ?? '';
      _bluetoothController.text = bluetoothName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrData = (_ssidController.text.isNotEmpty && _passwordController.text.isNotEmpty)
        ? jsonEncode({
            'ssid': _ssidController.text,
            'password': _passwordController.text,
            'security': _securityType,
            'bluetoothName': _bluetoothController.text.isNotEmpty ? _bluetoothController.text : null,
          })
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wi-Fi QR Generator"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(
                labelText: "Wi-Fi SSID",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bluetoothController,
              decoration: const InputDecoration(
                labelText: "Bluetooth Name (optional)",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Security Type"),
              trailing: DropdownButton<String>(
                value: _securityType,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _securityType = newValue);
                  }
                },
                items: ['WPA2', 'WPA', 'None'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Wi-Fi Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            if (qrData != null) ...[
              const Text("Scan this QR code using Raspberry Pi:"),
              const SizedBox(height: 10),
              Center(
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
