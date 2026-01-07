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
    final sessionInfo = data['session_info'] ?? {};
    final participantsData =
        data['participants'] as Map<dynamic, dynamic>? ?? {};
    final rules = sessionInfo['game_system_rules'] ?? {}; // 구조 수정 필요

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
      settings: GameSettings.fromMap(
        Map<String, dynamic>.from(rules),
      ), // TODO: 구조 맞추기
      expiresAt: DateTime.now().add(const Duration(hours: 1)), // 임시
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
    final boundary = data['activity_boundary'] ?? {};
    final jailData = data['jail_location'] ?? {};
    return GameSettings(
      timeLimit: data['game_duration_sec'] ?? 600,
      areaRadius: boundary['radius_meter'] ?? 300,
      center: LatLng(
        boundary['center_lat'] ?? 37.5665,
        boundary['center_lng'] ?? 126.9780,
      ),
      jail: LatLng(jailData['lat'] ?? 37.5665, jailData['lng'] ?? 126.9780),
      roleMethod: RoleAssignmentMethod.values.firstWhere(
        (e) => e.name == (data['role_method'] ?? 'manual'),
        orElse: () => RoleAssignmentMethod.manual,
      ),
    );
  }
}
