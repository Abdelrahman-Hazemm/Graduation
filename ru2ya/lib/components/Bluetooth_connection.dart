import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<ScanResult> scanResults = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _listenToBluetoothState();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  void _listenToBluetoothState() {
    FlutterBluePlus.adapterState.listen((state) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bluetooth is ${state.toString().split('.').last}')),
      );
    });
  }

  Future<void> _checkBluetoothStatus() async {
    final state = await FlutterBluePlus.adapterState.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bluetooth is ${state == BluetoothAdapterState.on ? "ON" : "OFF"}')),
    );
  }

  Future<void> _startScan() async {
    scanResults.clear();
    setState(() {});

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.platformName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Devices")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _checkBluetoothStatus,
            child: const Text("Check Bluetooth Status"),
          ),
          ElevatedButton(
            onPressed: _startScan,
            child: const Text("Scan for Devices"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                final device = result.device;

                return ListTile(
                  title: Text(device.platformName.isNotEmpty
                      ? device.platformName
                      : "Unnamed Device"),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(device),
                    child: const Text("Connect"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
