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
