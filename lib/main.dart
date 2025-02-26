import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as reactive_ble;

// Replace with your own unique UUIDs!
const String SERVICE_UUID = "YOUR_SERVICE_UUID"; // Replace this!
const String CHARACTERISTIC_UUID = "YOUR_CHARACTERISTIC_UUID"; // Replace this!

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothChat(),
    );
  }
}

class BluetoothChat extends StatefulWidget {
  @override
  _BluetoothChatState createState() => _BluetoothChatState();
}

class _BluetoothChatState extends State<BluetoothChat> {
  final reactive_ble.FlutterReactiveBle _ble =
      reactive_ble.FlutterReactiveBle();
  List<DiscoveredDevice> _discoveredDevices = [];
  BluetoothDevice? _connectedDevice;
  QualifiedCharacteristic? _messageCharacteristic;
  List<String> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  StreamSubscription<ConnectionStateUpdate>? _connectionStream;
  StreamSubscription<List<int>>? _characteristicStream;
  bool _isScanning = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _connectionStream?.cancel();
    _characteristicStream?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  void _startScan() async {
    _discoveredDevices = []; // Clear list
    setState(() {
      _isScanning = true;
    });

    _ble.scanForDevices(
        withServices: [Uuid.parse(SERVICE_UUID)],
        timeout: const Duration(seconds: 10)).listen((device) {
      if (!_discoveredDevices.any((d) => d.id == device.id)) {
        _discoveredDevices.add(device);
        setState(() {}); // Update UI
      }
    }, onError: (error) {
      print("Error scanning: $error");
      setState(() {
        _isScanning = false;
      });
    }, onDone: () {
      setState(() {
        _isScanning = false;
      });
    });
  }

  void _stopScan() {
    _ble.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  void _connect(DiscoveredDevice device) async {
    _connectionStream?.cancel();
    _characteristicStream?.cancel();

    _connectionStream =
        _ble.connectToDevice(id: device.id).listen((connectionState) async {
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        _connectedDevice = device;
        _isConnected = true;
        List<DiscoveredService> services =
            await _connectedDevice!.discoverServices();
        final service =
            services.firstWhere((s) => s.id == Uuid.parse(SERVICE_UUID));

        _messageCharacteristic = QualifiedCharacteristic(
            serviceId: service.id,
            characteristicId: Uuid.parse(CHARACTERISTIC_UUID));

        _characteristicStream = _ble
            .subscribeToCharacteristic(_messageCharacteristic!)
            .listen((data) {
          final message = utf8.decode(data);
          setState(() {
            _messages.add("Received: $message");
          });
        });

        setState(() {}); // Update UI
      } else if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        _connectedDevice = null;
        _messageCharacteristic = null;
        _isConnected = false;
        setState(() {
          _messages.add("Disconnected");
        });
      }
    });
  }

  void _sendMessage() async {
    if (_messageCharacteristic != null) {
      final message = _messageController.text;
      if (message.isNotEmpty) {
        try {
          await _ble.writeCharacteristicWithoutResponse(_messageCharacteristic!,
              Uint8List.fromList(utf8.encode(message)));

          setState(() {
            _messages.add("Sent: $message");
            _messageController.clear();
          });
        } catch (e) {
          print("Error sending message: $e");
          // Handle error, e.g., show a snackbar
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Chat")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isConnected) ...[
              ElevatedButton(
                onPressed: _isScanning ? null : _startScan,
                child: Text(_isScanning ? "Scanning..." : "Scan for Devices"),
              ),
              if (_discoveredDevices.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = _discoveredDevices[index];
                      return ListTile(
                        title:
                            Text(device.name ?? "Unknown"), // Handle null name
                        subtitle: Text(device.id),
                        onTap: () => _connect(device),
                      );
                    },
                  ),
                ),
              if (_isScanning && _discoveredDevices.isEmpty)
                const Center(child: CircularProgressIndicator()),
              if (!_isScanning && _discoveredDevices.isEmpty)
                const Center(child: Text("No devices found.")),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return Text(_messages[index]);
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration:
                          const InputDecoration(hintText: "Enter message"),
                    ),
                  ),
                  IconButton(
                      onPressed: _sendMessage, icon: const Icon(Icons.send)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
