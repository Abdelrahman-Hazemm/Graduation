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
          const SizedBox(height:15),
          InkWell(
            onTap: _checkBluetoothStatus,
            borderRadius: BorderRadius.circular(12.0), // nice ripple
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.blue, // background color
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Text(
                "Check Bluetooth Status",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          InkWell(
            onTap: _startScan,
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Text(
                "Scan for Devices",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          const SizedBox(height:20.0),

          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                final device = result.device;
                return ListTile(
                  title: Text(device.platformName.isNotEmpty
                      ? device.platformName
                      : "Unnamed Device",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),

                  ),
                  subtitle: Text(device.remoteId.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                  ),
                  ),
                  trailing: InkWell(
                    onTap: () => _connectToDevice(device),
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue, // background color
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: const Text(
                        "Connect",
                        style: TextStyle(
                          color: Colors.white, // text color
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
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
