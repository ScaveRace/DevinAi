import 'user.dart';

class Lobby {
  final String id;
  final String name;
  final String creatorId;
  final List<String> participantIds;
  final DateTime createdAt;
  
  Lobby({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.participantIds,
    required this.createdAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'creatorId': creatorId,
      'participantIds': participantIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
  
  factory Lobby.fromMap(Map<String, dynamic> map) {
    return Lobby(
      id: map['id'],
      name: map['name'],
      creatorId: map['creatorId'],
      participantIds: List<String>.from(map['participantIds']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
  
  Lobby copyWith({
    String? id,
    String? name,
    String? creatorId,
    List<String>? participantIds,
    DateTime? createdAt,
  }) {
    return Lobby(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
