import 'game_types.dart';

enum ChatType { global, team }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final ChatType type; // 'global' or 'team'
  final TeamRole? team; // Required if type is team

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.type,
    this.team,
  });

  factory ChatMessage.fromMap(String id, Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['nickname'] ?? map['senderName'] ?? 'Unknown',
      content: map['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      type: (map['type'] == 'team') ? ChatType.team : ChatType.global,
      team: map['team'] != null
          ? TeamRole.values.firstWhere(
              (e) => e.name == map['team'],
              orElse: () => TeamRole.unassigned,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'nickname': senderName,
      'message': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.name, // 'global' or 'team'
      'team': team?.name,
    };
  }
}
