import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'control_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? scanSubscription;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void startScan() async {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results
            .where((r) => r.device.platformName.isNotEmpty)
            .toList();
      });
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      setState(() {
        isScanning = scanning;
      });
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    scanSubscription?.cancel();
    setState(() {
      isScanning = false;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    stopScan();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        license: License.free,
      );

      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ControlPage(device: device)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
      }
    }
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Car Scanner'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scan Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: isScanning ? stopScan : startScan,
              icon: Icon(isScanning ? Icons.stop : Icons.search),
              label: Text(isScanning ? 'Stop Scan' : 'Scan for Devices'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (isScanning) const LinearProgressIndicator(),
          Expanded(
            child: scanResults.isEmpty
                ? Center(
                    child: Text(
                      isScanning
                          ? 'Scanning for devices...'
                          : 'Tap "Scan" to find your car',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      final result = scanResults[index];
                      final device = result.device;
                      final isEspCar = device.platformName == 'ESP32_CAR';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: isEspCar ? Colors.blue.shade900 : null,
                        child: ListTile(
                          leading: Icon(
                            isEspCar ? Icons.directions_car : Icons.bluetooth,
                            color: isEspCar ? Colors.green : null,
                          ),
                          title: Text(
                            device.platformName,
                            style: TextStyle(
                              fontWeight: isEspCar ? FontWeight.bold : null,
                            ),
                          ),
                          subtitle: Text(device.remoteId.toString()),
                          trailing: ElevatedButton(
                            onPressed: () => connectToDevice(device),
                            child: const Text('Connect'),
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
