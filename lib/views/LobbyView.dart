import 'package:flutter/material.dart';
import '../main.dart';
import 'CreateGameView.dart';

class LobbyView extends StatefulWidget {
  @override
  _LobbyViewState createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView> {
  List<String> newPlayers = [];
  bool startGame = false;
  bool navigateToLobby = false;
  
  // This would be set from the connection manager
  final String leaderName = "Leader Name"; // Placeholder for the actual leader name

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Equivalent to Color.bgCol
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                "$leaderName's Lobby", // Will show the leader's name
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Scrollable List for Players
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Leader shown first
                  playerRow(name: leaderName, role: "Leader"),
                  
                  // Current user (member)
                  playerRow(name: "Your Name", role: "Member"), // Will be replaced with actual name
                  
                  // Other joined Players
                  ...newPlayers.map((player) => playerRow(name: player, role: "Member")).toList(),
                ],
              ),
            ),
            
            // Start Game Button (visible only to leader in a real implementation)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // Start game action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Equivalent to Color.button
                    padding: EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Start Game",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget playerRow({required String name, required String role}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            name,
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Text(
            role,
            style: TextStyle(
              color: role == "Leader" ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
