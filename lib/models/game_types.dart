enum TeamRole {
  police,
  thief,
  unassigned;

  String get displayName {
    switch (this) {
      case TeamRole.police:
        return '경찰';
      case TeamRole.thief:
        return '도둑';
      case TeamRole.unassigned:
        return '팀 없음';
    }
  }
}

enum RoomStatus { waiting, playing, ended }

enum PlayerState {
  normal,
  captured,
  released, // 감옥에서 풀려난 직후 (무적 시간 등)
}

enum RoleAssignmentMethod {
  manual, // 자율
  host, // 지정
  random, // 랜덤
}

enum GameMode {
  basic, // 일반 모드 (추격전)
  advanced, // 고급 모드 (작전 모드)
}
