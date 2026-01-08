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
    print('DEBUG: GameSettings.fromMap data: $data'); // Debug Log
    // Try to read flat first (API style), then nested (legacy/DB style)
    final boundary = data['activity_boundary'] ?? {};
    final prisonData = data['prison_location'] ?? data['jail_location'] ?? {};

    return GameSettings(
      timeLimit: data['game_duration_sec'] ?? 600,
      areaRadius: (data['radius_meter'] ?? boundary['radius_meter'] ?? 300)
          .toInt(),
      center: LatLng(
        (data['center_lat'] ?? boundary['center_lat'] ?? 37.5665).toDouble(),
        (data['center_lng'] ?? boundary['center_lng'] ?? 126.9781).toDouble(),
      ),
      jail: LatLng(
        (data['prison_lat'] ?? prisonData['lat'] ?? 37.5665).toDouble(),
        (data['prison_lng'] ?? prisonData['lng'] ?? 126.9780).toDouble(),
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
      'role_assignment_mode': roleMethod.name, // Changed from role_method
      'center_lat': center.latitude,
      'center_lng': center.longitude,
      'radius_meter': areaRadius,
      'prison_lat': jail.latitude,
      'prison_lng': jail.longitude,
      'prison_radius_meter': 20, // Default
      'alert_on_exit': true, // Default
      'reveal_mode': 'always', // Default
      'is_gps_high_accuracy': true, // Default
      'police_can_see_thieves': true, // Default
      'thieves_can_see_police': false, // Default
      'capture_distance_meter': 5, // Default
      'require_button_press': true, // Default
      'capture_cooldown_sec': 3, // Default
      'release_distance_meter': 10, // Default
      'release_duration_sec': 5, // Default
      'interruptible': true, // Default
      'interrupt_distance_meter': 15, // Default
      'convenience_features': {
        'chat_enabled': true, // Enabled by default for now
        'voice_channel_id': null,
      },
    };
  }
}
