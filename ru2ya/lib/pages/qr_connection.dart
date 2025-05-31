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

    setState(() {
      _ssidController.text = ssid?.replaceAll('"', '') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrData =
        (_ssidController.text.isNotEmpty && _passwordController.text.isNotEmpty)
            ? jsonEncode({
                'ssid': _ssidController.text,
                'password': _passwordController.text,
                'security': _securityType,
              })
            : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _ssidController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: "Wi-Fi SSID",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.lightBlueAccent.withOpacity(0.05),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.black12, width: 2),
                ),
                prefixIcon: const Icon(Icons.wifi_outlined, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        "Security Type",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _securityType,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
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
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: "Wi-Fi Password",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.lightBlueAccent.withOpacity(0.05),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.black12, width: 2),
                ),
                prefixIcon: const Icon(Icons.wifi_password, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (qrData != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Scan this QR code using Raspberry Pi",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
