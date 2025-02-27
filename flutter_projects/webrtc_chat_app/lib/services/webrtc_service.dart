import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import '../models/message.dart';
import '../models/user.dart';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();
  
  // WebRTC related properties
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  
  // Stream controllers
  final StreamController<Message> _messageStreamController = StreamController<Message>.broadcast();
  Stream<Message> get messageStream => _messageStreamController.stream;
  
  // Current user and lobby info
  User? _currentUser;
  String? _currentLobbyId;
  
  // RTCPeerConnection configuration
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };
  
  factory WebRTCService() {
    return _instance;
  }
  
  WebRTCService._internal();
  
  void setCurrentUser(User user) {
    _currentUser = user;
  }
  
  void setCurrentLobby(String lobbyId) {
    _currentLobbyId = lobbyId;
  }
  
  Future<void> setupPeerConnections(List<String> participantIds) async {
    if (_currentUser == null || _currentLobbyId == null) {
      throw Exception('Current user or lobby not set');
    }
    
    // Filter out current user
    final otherParticipantIds = participantIds.where((id) => id != _currentUser!.id).toList();
    
    // Create peer connections for each participant
    for (final participantId in otherParticipantIds) {
      if (!_peerConnections.containsKey(participantId)) {
        await _createPeerConnection(participantId);
      }
    }
    
    // Listen for signaling messages
    _listenForSignalingMessages();
  }
  
  Future<void> _createPeerConnection(String participantId) async {
    // Create peer connection
    final peerConnection = await createPeerConnection(_configuration);
    _peerConnections[participantId] = peerConnection;
    
    // Setup data channel
    final dataChannelInit = RTCDataChannelInit();
    dataChannelInit.ordered = true;
    
    final dataChannel = await peerConnection.createDataChannel('chat', dataChannelInit);
    _dataChannels[participantId] = dataChannel;
    
    _setupDataChannel(dataChannel, participantId);
    
    // Set up event listeners
    peerConnection.onIceCandidate = (candidate) {
      _sendIceCandidate(participantId, candidate);
    };
    
    peerConnection.onDataChannel = (channel) {
      _setupDataChannel(channel, participantId);
    };
    
    // Create offer if we are the initiator (determined by user ID comparison)
    if (_currentUser!.id.compareTo(participantId) < 0) {
      await _createOffer(participantId);
    }
  }
  
  void _setupDataChannel(RTCDataChannel dataChannel, String participantId) {
    dataChannel.onMessage = (message) {
      final data = jsonDecode(message.text);
      
      if (data['type'] == 'chat') {
        final chatMessage = Message(
          id: data['id'],
          senderId: data['senderId'],
          senderName: data['senderName'],
          content: data['content'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
          lobbyId: data['lobbyId'],
        );
        
        _messageStreamController.add(chatMessage);
      }
    };
    
    dataChannel.onDataChannelState = (state) {
      print('Data channel state: $state for participant: $participantId');
    };
  }
  
  Future<void> _createOffer(String participantId) async {
    final peerConnection = _peerConnections[participantId];
    if (peerConnection == null) return;
    
    try {
      final offer = await peerConnection.createOffer();
      await peerConnection.setLocalDescription(offer);
      
      // Send offer to remote peer via Firestore
      await _firestore
          .collection('lobbies')
          .doc(_currentLobbyId)
          .collection('signaling')
          .doc('${_currentUser!.id}_$participantId')
          .set({
        'type': 'offer',
        'sdp': offer.sdp,
        'from': _currentUser!.id,
        'to': participantId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating offer: $e');
    }
  }
  
  Future<void> _handleOffer(String from, RTCSessionDescription offer) async {
    final peerConnection = _peerConnections[from];
    if (peerConnection == null) return;
    
    try {
      await peerConnection.setRemoteDescription(offer);
      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);
      
      // Send answer to remote peer via Firestore
      await _firestore
          .collection('lobbies')
          .doc(_currentLobbyId)
          .collection('signaling')
          .doc('${_currentUser!.id}_$from')
          .set({
        'type': 'answer',
        'sdp': answer.sdp,
        'from': _currentUser!.id,
        'to': from,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error handling offer: $e');
    }
  }
  
  Future<void> _handleAnswer(String from, RTCSessionDescription answer) async {
    final peerConnection = _peerConnections[from];
    if (peerConnection == null) return;
    
    try {
      await peerConnection.setRemoteDescription(answer);
    } catch (e) {
      print('Error handling answer: $e');
    }
  }
  
  Future<void> _sendIceCandidate(String to, RTCIceCandidate candidate) async {
    try {
      await _firestore
          .collection('lobbies')
          .doc(_currentLobbyId)
          .collection('signaling')
          .add({
        'type': 'ice_candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'from': _currentUser!.id,
        'to': to,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending ICE candidate: $e');
    }
  }
  
  Future<void> _handleIceCandidate(
      String from, String candidate, String? sdpMid, int? sdpMLineIndex) async {
    final peerConnection = _peerConnections[from];
    if (peerConnection == null) return;
    
    try {
      final iceCandidate = RTCIceCandidate(
        candidate,
        sdpMid,
        sdpMLineIndex,
      );
      await peerConnection.addCandidate(iceCandidate);
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }
  
  void _listenForSignalingMessages() {
    _firestore
        .collection('lobbies')
        .doc(_currentLobbyId)
        .collection('signaling')
        .where('to', isEqualTo: _currentUser!.id)
        .snapshots()
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final from = data['from'] as String;
        final type = data['type'] as String;
        
        switch (type) {
          case 'offer':
            if (!_peerConnections.containsKey(from)) {
              await _createPeerConnection(from);
            }
            await _handleOffer(
              from,
              RTCSessionDescription(data['sdp'] as String, 'offer'),
            );
            break;
          case 'answer':
            await _handleAnswer(
              from,
              RTCSessionDescription(data['sdp'] as String, 'answer'),
            );
            break;
          case 'ice_candidate':
            await _handleIceCandidate(
              from,
              data['candidate'] as String,
              data['sdpMid'] as String?,
              data['sdpMLineIndex'] as int?,
            );
            break;
        }
        
        // Delete the processed signaling message
        await doc.reference.delete();
      }
    });
  }
  
  Future<void> sendMessage(String content) async {
    if (_currentUser == null || _currentLobbyId == null) {
      throw Exception('Current user or lobby not set');
    }
    
    final message = Message(
      id: _uuid.v4(),
      senderId: _currentUser!.id,
      senderName: _currentUser!.name,
      content: content,
      timestamp: DateTime.now(),
      lobbyId: _currentLobbyId!,
    );
    
    // Add message to local stream
    _messageStreamController.add(message);
    
    // Send message to all peers
    final messageData = {
      'type': 'chat',
      'id': message.id,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'content': message.content,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'lobbyId': message.lobbyId,
    };
    
    final messageJson = jsonEncode(messageData);
    
    for (final dataChannel in _dataChannels.values) {
      if (dataChannel.state == RTCDataChannelState.RTCDataChannelOpen) {
        dataChannel.send(RTCDataChannelMessage(messageJson));
      }
    }
  }
  
  Future<void> leaveLobby() async {
    // Close all peer connections and data channels
    for (final dataChannel in _dataChannels.values) {
      dataChannel.close();
    }
    
    for (final peerConnection in _peerConnections.values) {
      peerConnection.close();
    }
    
    _dataChannels.clear();
    _peerConnections.clear();
    
    // Clear current lobby
    _currentLobbyId = null;
  }
  
  void dispose() {
    for (final dataChannel in _dataChannels.values) {
      dataChannel.close();
    }
    
    for (final peerConnection in _peerConnections.values) {
      peerConnection.close();
    }
    
    _messageStreamController.close();
  }
}
