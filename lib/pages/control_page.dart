import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../widgets/direction_button.dart';
import '../widgets/stop_button.dart';

class ControlPage extends StatefulWidget {
  final BluetoothDevice device;

  const ControlPage({super.key, required this.device});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  BluetoothCharacteristic? commandCharacteristic;
  bool isConnected = true;
  int speed = 150;

  // UUIDs matching your ESP32 code
  final String serviceUuid = "12345678-1234-1234-1234-1234567890ab";
  final String characteristicUuid = "abcd1234-5678-90ab-cdef-1234567890ab";

  @override
  void initState() {
    super.initState();
    discoverServices();

    widget.device.connectionState.listen((state) {
      setState(() {
        isConnected = state == BluetoothConnectionState.connected;
      });
      if (!isConnected && mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> discoverServices() async {
    try {
      List<BluetoothService> services = await widget.device.discoverServices();

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            serviceUuid.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() ==
                characteristicUuid.toLowerCase()) {
              setState(() {
                commandCharacteristic = char;
              });
              return;
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Car service not found!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> sendCommand(String command, {int? customSpeed}) async {
    if (commandCharacteristic == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not connected to car!')));
      return;
    }

    try {
      final speedToUse = customSpeed ?? speed;
      String fullCommand = command == 'S' ? command : '$command,$speedToUse';
      await commandCharacteristic!.write(
        utf8.encode(fullCommand),
        withoutResponse: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  void disconnect() async {
    await widget.device.disconnect();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: disconnect,
          ),
        ],
      ),
      body: commandCharacteristic == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Connection status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isConnected ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'Connected' : 'Disconnected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Speed slider
                  Text(
                    'Speed: $speed',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: speed.toDouble(),
                    min: 50,
                    max: 255,
                    divisions: 41,
                    label: speed.toString(),
                    onChanged: (value) {
                      setState(() {
                        speed = value.toInt();
                      });
                    },
                  ),

                  const Spacer(),

                  // Control buttons
                  DirectionButton(
                    icon: Icons.arrow_upward,
                    label: 'FORWARD',
                    onPressed: () => sendCommand('F'),
                    onReleased: () => sendCommand('S'),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DirectionButton(
                        icon: Icons.arrow_back,
                        label: 'LEFT',
                        onPressed: () => sendCommand('L'),
                        onReleased: () => sendCommand('S'),
                      ),
                      const SizedBox(width: 20),
                      StopButton(onPressed: () => sendCommand('S')),
                      const SizedBox(width: 20),
                      DirectionButton(
                        icon: Icons.arrow_forward,
                        label: 'RIGHT',
                        onPressed: () => sendCommand('R'),
                        onReleased: () => sendCommand('S'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  DirectionButton(
                    icon: Icons.arrow_downward,
                    label: 'BACKWARD',
                    onPressed: () => sendCommand('B'),
                    onReleased: () => sendCommand('S'),
                  ),

                  const Spacer(),
                ],
              ),
            ),
    );
  }
}
