import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/lobby.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';
import 'chat_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _lobbyNameController = TextEditingController();
  bool _isCreatingLobby = false;
  
  @override
  void dispose() {
    _lobbyNameController.dispose();
    super.dispose();
  }
  
  void _showCreateLobbyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Lobby'),
        content: TextField(
          controller: _lobbyNameController,
          decoration: const InputDecoration(
            labelText: 'Lobby Name',
            hintText: 'Enter a name for your lobby',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _lobbyNameController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_lobbyNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a lobby name')),
                );
                return;
              }
              
              setState(() {
                _isCreatingLobby = true;
              });
              
              Navigator.of(context).pop();
              
              try {
                final user = Provider.of<UserProvider>(context, listen: false).user;
                if (user == null) {
                  throw Exception('User not found');
                }
                
                final lobby = await FirebaseService().createLobby(
                  _lobbyNameController.text.trim(),
                  user.id,
                );
                
                if (!mounted) return;
                
                // Navigate to chat screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(lobby: lobby),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating lobby: $e')),
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _isCreatingLobby = false;
                    _lobbyNameController.clear();
                  });
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  void _joinLobby(Lobby lobby) async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) {
        throw Exception('User not found');
      }
      
      // Only join if not already a participant
      if (!lobby.participantIds.contains(user.id)) {
        await FirebaseService().joinLobby(lobby.id, user.id);
      }
      
      if (!mounted) return;
      
      // Navigate to chat screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(lobby: lobby),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining lobby: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobbies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).clearUser();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Welcome, ${user?.name ?? "User"}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isCreatingLobby ? null : _showCreateLobbyDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Lobby'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Lobby>>(
              stream: FirebaseService().getLobbies(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                final lobbies = snapshot.data ?? [];
                
                if (lobbies.isEmpty) {
                  return const Center(
                    child: Text('No lobbies available. Create one!'),
                  );
                }
                
                return ListView.builder(
                  itemCount: lobbies.length,
                  itemBuilder: (context, index) {
                    final lobby = lobbies[index];
                    final isCreator = user?.id == lobby.creatorId;
                    final isParticipant = lobby.participantIds.contains(user?.id);
                    
                    return ListTile(
                      title: Text(lobby.name),
                      subtitle: Text('${lobby.participantIds.length} participants'),
                      trailing: isCreator || isParticipant
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : ElevatedButton(
                              onPressed: () => _joinLobby(lobby),
                              child: const Text('Join'),
                            ),
                      onTap: () => _joinLobby(lobby),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
