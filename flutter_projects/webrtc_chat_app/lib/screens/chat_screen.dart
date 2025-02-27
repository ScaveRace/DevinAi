import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/lobby.dart';
import '../models/message.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';
import '../services/webrtc_service.dart';
import '../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final Lobby lobby;
  
  const ChatScreen({super.key, required this.lobby});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  final WebRTCService _webRTCService = WebRTCService();
  final NotificationService _notificationService = NotificationService();
  bool _isConnecting = true;
  
  @override
  void initState() {
    super.initState();
    _setupWebRTC();
    _setupNotifications();
  }
  
  Future<void> _setupWebRTC() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }
    
    setState(() {
      _isConnecting = true;
    });
    
    try {
      // Set current user and lobby
      _webRTCService.setCurrentUser(user);
      _webRTCService.setCurrentLobby(widget.lobby.id);
      
      // Setup peer connections
      await _webRTCService.setupPeerConnections(widget.lobby.participantIds);
      
      // Listen for messages
      _webRTCService.messageStream.listen(_handleNewMessage);
      
      setState(() {
        _isConnecting = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting up WebRTC: $e')),
      );
      setState(() {
        _isConnecting = false;
      });
    }
  }
  
  Future<void> _setupNotifications() async {
    await _notificationService.initialize();
  }
  
  void _handleNewMessage(Message message) {
    setState(() {
      _messages.add(message);
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // Show notification if message is not from current user
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null && message.senderId != user.id) {
      _notificationService.showNotification(
        title: message.senderName,
        body: message.content,
        payload: widget.lobby.id,
      );
    }
  }
  
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    try {
      await _webRTCService.sendMessage(_messageController.text.trim());
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }
  
  Future<void> _leaveLobby() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;
    
    try {
      // Close WebRTC connections
      await _webRTCService.leaveLobby();
      
      // Remove user from lobby in Firestore
      await FirebaseService().leaveLobby(widget.lobby.id, user.id);
      
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving lobby: $e')),
      );
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    
    return WillPopScope(
      onWillPop: () async {
        await _leaveLobby();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lobby.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                await _leaveLobby();
                if (!mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: _isConnecting
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connecting to peers...'),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? const Center(
                            child: Text('No messages yet. Start chatting!'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isCurrentUser = message.senderId == user?.id;
                              
                              return Align(
                                alignment: isCurrentUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                    horizontal: 8.0,
                                  ),
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? Colors.blue[100]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isCurrentUser)
                                        Text(
                                          message.senderName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      Text(message.content),
                                      Text(
                                        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 10.0,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(24.0),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        FloatingActionButton(
                          onPressed: _sendMessage,
                          mini: true,
                          child: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
