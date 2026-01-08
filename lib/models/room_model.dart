import 'package:latlong2/latlong.dart';
import 'game_types.dart';

class RoomModel {
  final String roomId;
  final String hostId;
  final String pinCode;
  final RoomStatus status;
  final GameSettings settings;
  final DateTime expiresAt;
  final Map<String, ParticipantInfo> participants;

  RoomModel({
    required this.roomId,
    required this.hostId,
    required this.pinCode,
    required this.status,
    required this.settings,
    required this.expiresAt,
    required this.participants,
  });

  // fromJson 등 구현 필요 (Firebase Realtime DB 구조에 맞게)
  factory RoomModel.fromMap(String id, Map<String, dynamic> data) {
    // API response structure for join/create might be different.
    // Assuming 'session_info' or direct fields.
    // If data comes from 'Join Room' response:
    // { "room_id": "...", "session_info": {...}, "participants": {...} }

    final sessionInfo = data['session_info'] as Map<String, dynamic>? ?? data;
    final participantsData =
        data['participants'] as Map<dynamic, dynamic>? ?? {};

    // Check if settings are in session_info or root
    final settingsMap =
        sessionInfo['game_system_rules'] as Map<String, dynamic>? ??
        sessionInfo;

    // participants parsing
    final parsedParticipants = <String, ParticipantInfo>{};
    participantsData.forEach((key, value) {
      if (key is String && value is Map) {
        parsedParticipants[key] = ParticipantInfo.fromMap(
          Map<String, dynamic>.from(value),
        );
      }
    });

    return RoomModel(
      roomId: id,
      hostId: sessionInfo['host_id'] ?? '',
      pinCode: sessionInfo['pin_code'] ?? '',
      status: RoomStatus.values.firstWhere(
        (e) => e.name == (sessionInfo['status'] ?? 'waiting'),
        orElse: () => RoomStatus.waiting,
      ),
      settings: GameSettings.fromMap(settingsMap),
      expiresAt: sessionInfo['expires_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              sessionInfo['expires_at'] is int
                  ? sessionInfo['expires_at']
                  : int.parse(sessionInfo['expires_at'].toString()),
            )
          : DateTime.now().add(const Duration(hours: 1)),
      participants: parsedParticipants,
    );
  }
}

class ParticipantInfo {
  final String nickname;
  final TeamRole team;
  final bool isReady;

  ParticipantInfo({
    required this.nickname,
    required this.team,
    required this.isReady,
  });

  factory ParticipantInfo.fromMap(Map<String, dynamic> data) {
    return ParticipantInfo(
      nickname: data['nickname'] ?? 'Unknown',
      team: TeamRole.values.firstWhere(
        (e) => e.name == (data['team'] ?? 'unassigned'),
        orElse: () => TeamRole.unassigned,
      ),
      isReady: data['ready'] ?? false,
    );
  }
}

class GameSettings {
  final int timeLimit;
  final int areaRadius;
  final LatLng center;
  final LatLng jail;
  final RoleAssignmentMethod roleMethod;

  GameSettings({
    required this.timeLimit,
    required this.areaRadius,
    required this.center,
    required this.jail,
    required this.roleMethod,
  });

  factory GameSettings.fromMap(Map<String, dynamic> data) {
    // Try to read flat first (API style), then nested (legacy/DB style)
    final boundary = data['activity_boundary'] ?? {};
    final jailData = data['jail_location'] ?? {};

    return GameSettings(
      timeLimit: data['game_duration_sec'] ?? 600,
      areaRadius: data['radius_meter'] ?? boundary['radius_meter'] ?? 300,
      center: LatLng(
        (data['center_lat'] ?? boundary['center_lat'] ?? 37.5665).toDouble(),
        (data['center_lng'] ?? boundary['center_lng'] ?? 126.9780).toDouble(),
      ),
      jail: LatLng(
        (data['prison_lat'] ?? jailData['lat'] ?? 37.5665).toDouble(),
        (data['prison_lng'] ?? jailData['lng'] ?? 126.9780).toDouble(),
      ),
      roleMethod: RoleAssignmentMethod.values.firstWhere(
        (e) => e.name == (data['role_method'] ?? 'manual'),
        orElse: () => RoleAssignmentMethod.manual,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_duration_sec': timeLimit,
      'radius_meter': areaRadius,
      'center_lat': center.latitude,
      'center_lng': center.longitude,
      'prison_lat': jail.latitude,
      'prison_lng': jail.longitude,
      'role_method': roleMethod.name,
      // Add default location policy data if needed by API
      'location_policy': {
        'reveal_mode': 'always',
        'police_can_see_thieves': true,
        'thieves_can_see_police': false,
      },
    };
  }
}
