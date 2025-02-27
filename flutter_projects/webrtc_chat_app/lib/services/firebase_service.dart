import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';

import '../models/lobby.dart';
import '../models/user.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();
  
  factory FirebaseService() {
    return _instance;
  }
  
  FirebaseService._internal();
  
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }
  
  // User methods
  Future<User> createUser(String name) async {
    final String userId = _uuid.v4();
    final User user = User(id: userId, name: name);
    
    await _firestore.collection('users').doc(userId).set(user.toMap());
    return user;
  }
  
  // Lobby methods
  Future<Lobby> createLobby(String name, String creatorId) async {
    final String lobbyId = _uuid.v4();
    final Lobby lobby = Lobby(
      id: lobbyId,
      name: name,
      creatorId: creatorId,
      participantIds: [creatorId],
      createdAt: DateTime.now(),
    );
    
    await _firestore.collection('lobbies').doc(lobbyId).set(lobby.toMap());
    return lobby;
  }
  
  Future<void> joinLobby(String lobbyId, String userId) async {
    await _firestore.collection('lobbies').doc(lobbyId).update({
      'participantIds': FieldValue.arrayUnion([userId]),
    });
  }
  
  Future<void> leaveLobby(String lobbyId, String userId) async {
    await _firestore.collection('lobbies').doc(lobbyId).update({
      'participantIds': FieldValue.arrayRemove([userId]),
    });
    
    // Check if lobby is empty and delete if it is
    final lobbyDoc = await _firestore.collection('lobbies').doc(lobbyId).get();
    final lobby = Lobby.fromMap(lobbyDoc.data()!);
    
    if (lobby.participantIds.isEmpty) {
      await _firestore.collection('lobbies').doc(lobbyId).delete();
    }
  }
  
  Stream<List<Lobby>> getLobbies() {
    return _firestore
        .collection('lobbies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Lobby.fromMap(doc.data())).toList();
    });
  }
  
  Stream<Lobby> getLobby(String lobbyId) {
    return _firestore
        .collection('lobbies')
        .doc(lobbyId)
        .snapshots()
        .map((snapshot) => Lobby.fromMap(snapshot.data()!));
  }
}
