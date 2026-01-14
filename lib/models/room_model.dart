/// 방(Room) 세션 정보 모델
/// CnR.json > realtime_db_live_data > node_rooms
class RoomModel {
  final String roomId;
  final SessionInfo sessionInfo;
  final Map<String, Participant> participants;
  final GameSystemRules gameSystemRules;
  final ConvenienceFeatures? convenienceFeatures;

  RoomModel({
    required this.roomId,
    required this.sessionInfo,
    required this.participants,
    required this.gameSystemRules,
    this.convenienceFeatures,
  });

  /// Realtime DB 데이터를 RoomModel로 변환
  factory RoomModel.fromMap(String roomId, Map<String, dynamic> data) {
    return RoomModel(
      roomId: roomId,
      sessionInfo: SessionInfo.fromMap(
        data['session_info'] != null
            ? Map<String, dynamic>.from(data['session_info'] as Map)
            : {},
      ),
      participants: (data['participants'] as Map<dynamic, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key.toString(),
          Participant.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      gameSystemRules: GameSystemRules.fromMap(
        data['game_system_rules'] != null
            ? Map<String, dynamic>.from(data['game_system_rules'] as Map)
            : {},
      ),
      convenienceFeatures: data['convenience_features'] != null
          ? ConvenienceFeatures.fromMap(
              Map<String, dynamic>.from(data['convenience_features'] as Map),
            )
          : null,
    );
  }

  /// RoomModel을 Realtime DB 데이터로 변환
  Map<String, dynamic> toMap() {
    return {
      'session_info': sessionInfo.toMap(),
      'participants': participants.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'game_system_rules': gameSystemRules.toMap(),
      if (convenienceFeatures != null)
        'convenience_features': convenienceFeatures!.toMap(),
    };
  }
}

/// 세션 정보
class SessionInfo {
  final String status; // waiting | playing | cleaning | force_ended
  final String hostId;
  final DateTime expiresAt;
  final String pinCode;
  final ForceEnd? forceEnd;

  SessionInfo({
    required this.status,
    required this.hostId,
    required this.expiresAt,
    required this.pinCode,
    this.forceEnd,
  });

  factory SessionInfo.fromMap(Map<String, dynamic> data) {
    return SessionInfo(
      status: data['status'] as String? ?? 'waiting',
      hostId: data['host_id'] as String? ?? '',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        data['expires_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      pinCode: data['pin_code'] as String? ?? '',
      forceEnd: data['force_end'] != null
          ? ForceEnd.fromMap(
              Map<String, dynamic>.from(data['force_end'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'host_id': hostId,
      'expires_at': expiresAt.millisecondsSinceEpoch,
      'pin_code': pinCode,
      if (forceEnd != null) 'force_end': forceEnd!.toMap(),
    };
  }
}

/// 강제 종료 정보
class ForceEnd {
  final String endedBy;
  final DateTime endedAt;
  final String reason; // host_terminated | insufficient_players

  ForceEnd({
    required this.endedBy,
    required this.endedAt,
    required this.reason,
  });

  factory ForceEnd.fromMap(Map<String, dynamic> data) {
    return ForceEnd(
      endedBy: data['ended_by'] as String? ?? '',
      endedAt: DateTime.fromMillisecondsSinceEpoch(
        data['ended_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      reason: data['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ended_by': endedBy,
      'ended_at': endedAt.millisecondsSinceEpoch,
      'reason': reason,
    };
  }
}

/// 참가자 정보
class Participant {
  final String nickname;
  final bool ready;
  final String team; // police | thief | unassigned
  final int joinedAt;

  Participant({
    required this.nickname,
    required this.ready,
    required this.team,
    this.joinedAt = 0,
  });

  factory Participant.fromMap(Map<String, dynamic> data) {
    return Participant(
      nickname: data['nickname'] as String? ?? 'Unknown',
      ready: data['ready'] as bool? ?? false,
      team: data['team'] as String? ?? 'unassigned',
      joinedAt: data['joined_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'ready': ready,
      'team': team,
      'joined_at': joinedAt,
    };
  }
}

/// 게임 시스템 규칙
class GameSystemRules {
  final int gameDurationSec;
  final int minPlayers;
  final int maxPlayers;
  final int policeCount;
  final String roleAssignmentMode; // 'host', 'user', 'random'
  final ActivityBoundary activityBoundary;
  final PrisonLocation prisonLocation;
  final LocationPolicy locationPolicy;
  final CaptureRules captureRules;
  final ReleaseRules releaseRules;
  final VictoryConditions victoryConditions;
  final String gameMode; // 'basic', 'advanced'

  GameSystemRules({
    required this.gameDurationSec,
    required this.minPlayers,
    required this.maxPlayers,
    this.policeCount = 1,
    this.roleAssignmentMode = 'host',
    required this.activityBoundary,
    required this.prisonLocation,
    required this.locationPolicy,
    required this.captureRules,
    required this.releaseRules,
    required this.victoryConditions,
    this.gameMode = 'basic',
  });

  factory GameSystemRules.fromMap(Map<String, dynamic> data) {
    return GameSystemRules(
      gameDurationSec: data['game_duration_sec'] as int? ?? 600,
      minPlayers: data['min_players'] as int? ?? 4,
      maxPlayers: data['max_players'] as int? ?? 10,
      policeCount: data['police_count'] as int? ?? 1,
      roleAssignmentMode: data['role_assignment_mode'] as String? ?? 'host',
      activityBoundary: ActivityBoundary.fromMap(
        data['activity_boundary'] != null
            ? Map<String, dynamic>.from(data['activity_boundary'] as Map)
            : {},
      ),
      prisonLocation: PrisonLocation.fromMap(
        data['prison_location'] != null
            ? Map<String, dynamic>.from(data['prison_location'] as Map)
            : {},
      ),
      locationPolicy: LocationPolicy.fromMap(
        data['location_policy'] != null
            ? Map<String, dynamic>.from(data['location_policy'] as Map)
            : {},
      ),
      captureRules: CaptureRules.fromMap(
        data['capture_rules'] != null
            ? Map<String, dynamic>.from(data['capture_rules'] as Map)
            : {},
      ),
      releaseRules: ReleaseRules.fromMap(
        data['release_rules'] != null
            ? Map<String, dynamic>.from(data['release_rules'] as Map)
            : {},
      ),
      victoryConditions: VictoryConditions.fromMap(
        data['victory_conditions'] != null
            ? Map<String, dynamic>.from(data['victory_conditions'] as Map)
            : {},
      ),
      gameMode: data['game_mode'] as String? ?? 'basic',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'game_duration_sec': gameDurationSec,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'police_count': policeCount,
      'role_assignment_mode': roleAssignmentMode,
      'activity_boundary': activityBoundary.toMap(),
      'prison_location': prisonLocation.toMap(),
      'location_policy': locationPolicy.toMap(),
      'capture_rules': captureRules.toMap(),
      'release_rules': releaseRules.toMap(),
      'victory_conditions': victoryConditions.toMap(),
      'game_mode': gameMode,
    };
  }
}

/// 활동 경계
class ActivityBoundary {
  final double centerLat;
  final double centerLng;
  final int radiusMeter;
  final bool alertOnExit;

  ActivityBoundary({
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeter,
    required this.alertOnExit,
  });

  factory ActivityBoundary.fromMap(Map<String, dynamic> data) {
    return ActivityBoundary(
      centerLat: (data['center_lat'] as num?)?.toDouble() ?? 37.5665,
      centerLng: (data['center_lng'] as num?)?.toDouble() ?? 126.9780,
      radiusMeter: data['radius_meter'] as int? ?? 300,
      alertOnExit: data['alert_on_exit'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'center_lat': centerLat,
      'center_lng': centerLng,
      'radius_meter': radiusMeter,
      'alert_on_exit': alertOnExit,
    };
  }
}

/// 감옥 위치
class PrisonLocation {
  final double lat;
  final double lng;
  final int radiusMeter;

  PrisonLocation({
    required this.lat,
    required this.lng,
    required this.radiusMeter,
  });

  factory PrisonLocation.fromMap(Map<String, dynamic> data) {
    return PrisonLocation(
      lat: (data['lat'] as num?)?.toDouble() ?? 37.5665,
      lng: (data['lng'] as num?)?.toDouble() ?? 126.9780,
      radiusMeter: data['radius_meter'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toMap() {
    return {'lat': lat, 'lng': lng, 'radius_meter': radiusMeter};
  }
}

/// 위치 공개 정책
class LocationPolicy {
  final String revealMode; // always | interval
  final int? revealIntervalSec;
  final bool isGpsHighAccuracy;
  final bool policeCanSeeThieves;
  final bool thievesCanSeePolice;

  LocationPolicy({
    required this.revealMode,
    this.revealIntervalSec,
    required this.isGpsHighAccuracy,
    required this.policeCanSeeThieves,
    required this.thievesCanSeePolice,
  });

  factory LocationPolicy.fromMap(Map<String, dynamic> data) {
    return LocationPolicy(
      revealMode: data['reveal_mode'] as String? ?? 'always',
      revealIntervalSec: data['reveal_interval_sec'] as int?,
      isGpsHighAccuracy: data['is_gps_high_accuracy'] as bool? ?? true,
      policeCanSeeThieves: data['police_can_see_thieves'] as bool? ?? true,
      thievesCanSeePolice: data['thieves_can_see_police'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reveal_mode': revealMode,
      if (revealIntervalSec != null) 'reveal_interval_sec': revealIntervalSec,
      'is_gps_high_accuracy': isGpsHighAccuracy,
      'police_can_see_thieves': policeCanSeeThieves,
      'thieves_can_see_police': thievesCanSeePolice,
    };
  }
}

/// 검거 규칙
class CaptureRules {
  final int triggerDistanceMeter;
  final bool requireButtonPress;
  final int captureCooldownSec;
  final bool validateOnServer;

  CaptureRules({
    required this.triggerDistanceMeter,
    required this.requireButtonPress,
    required this.captureCooldownSec,
    required this.validateOnServer,
  });

  factory CaptureRules.fromMap(Map<String, dynamic> data) {
    return CaptureRules(
      triggerDistanceMeter: data['trigger_distance_meter'] as int? ?? 3,
      requireButtonPress: data['require_button_press'] as bool? ?? true,
      captureCooldownSec: data['capture_cooldown_sec'] as int? ?? 10,
      validateOnServer: data['validate_on_server'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trigger_distance_meter': triggerDistanceMeter,
      'require_button_press': requireButtonPress,
      'capture_cooldown_sec': captureCooldownSec,
      'validate_on_server': validateOnServer,
    };
  }
}

/// 구출 규칙
class ReleaseRules {
  final int triggerDistanceMeter;
  final int releaseDurationSec;
  final bool interruptible;
  final int interruptDistanceMeter;

  ReleaseRules({
    required this.triggerDistanceMeter,
    required this.releaseDurationSec,
    required this.interruptible,
    required this.interruptDistanceMeter,
  });

  factory ReleaseRules.fromMap(Map<String, dynamic> data) {
    return ReleaseRules(
      triggerDistanceMeter: data['trigger_distance_meter'] as int? ?? 5,
      releaseDurationSec: data['release_duration_sec'] as int? ?? 5,
      interruptible: data['interruptible'] as bool? ?? true,
      interruptDistanceMeter: data['interrupt_distance_meter'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trigger_distance_meter': triggerDistanceMeter,
      'release_duration_sec': releaseDurationSec,
      'interruptible': interruptible,
      'interrupt_distance_meter': interruptDistanceMeter,
    };
  }
}

/// 승리 조건
class VictoryConditions {
  final String policeWin;
  final String thiefWin;

  VictoryConditions({required this.policeWin, required this.thiefWin});

  factory VictoryConditions.fromMap(Map<String, dynamic> data) {
    return VictoryConditions(
      policeWin: data['police_win'] as String? ?? 'all_thieves_captured',
      thiefWin: data['thief_win'] as String? ?? 'time_limit',
    );
  }

  Map<String, dynamic> toMap() {
    return {'police_win': policeWin, 'thief_win': thiefWin};
  }
}

/// 편의 기능
class ConvenienceFeatures {
  final String? voiceChannelId;
  final bool chatEnabled;

  ConvenienceFeatures({this.voiceChannelId, required this.chatEnabled});

  factory ConvenienceFeatures.fromMap(Map<String, dynamic> data) {
    return ConvenienceFeatures(
      voiceChannelId: data['voice_channel_id'] as String?,
      chatEnabled: data['chat_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (voiceChannelId != null) 'voice_channel_id': voiceChannelId,
      'chat_enabled': chatEnabled,
    };
  }
}
