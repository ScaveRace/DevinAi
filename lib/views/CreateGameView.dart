import 'package:flutter/material.dart';
import '../main.dart';

class CreateGameView extends StatefulWidget {
  @override
  _CreateGameViewState createState() => _CreateGameViewState();
}

class _CreateGameViewState extends State<CreateGameView> {
  List<String> newPlayers = [];
  bool startGame = false;
  bool navigateToLobby = false;

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
                "Your Name's Lobby", // Will be replaced with actual name
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
                  // Leader
                  playerRow(name: "Your Name", role: "Leader"), // Will be replaced with actual name
                  
                  // Joined Players
                  ...newPlayers.map((player) => playerRow(name: player, role: "Member")).toList(),
                ],
              ),
            ),
            
            // Start Game Button
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
