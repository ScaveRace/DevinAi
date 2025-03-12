import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as reactive_ble;
import 'views/CreateGameView.dart';
import 'views/LobbyView.dart';

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
      theme: ThemeData.dark(),
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
    super.dispose();
  }
