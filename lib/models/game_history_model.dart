/// 게임 종료 후 저장될 결과 데이터 모델
class GameHistory {
  final String roomId;
  final String hostId;
  final String winningTeam; // 'police' or 'thief'
  final String winReason; // 'all_thieves_captured', 'time_limit' 등
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final List<GameParticipantResult> participants;

  GameHistory({
    required this.roomId,
    required this.hostId,
    required this.winningTeam,
    required this.winReason,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    required this.participants,
  });

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'host_id': hostId,
      'winning_team': winningTeam,
      'win_reason': winReason,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_sec': durationSec,
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }

  factory GameHistory.fromJson(Map<String, dynamic> map) {
    return GameHistory(
      roomId: map['room_id'] ?? '',
      hostId: map['host_id'] ?? '',
      winningTeam: map['winning_team'] ?? 'unknown',
      winReason: map['win_reason'] ?? 'unknown',
      startedAt: DateTime.tryParse(map['started_at'] ?? '') ?? DateTime.now(),
      endedAt: DateTime.tryParse(map['ended_at'] ?? '') ?? DateTime.now(),
      durationSec: map['duration_sec'] ?? 0,
      participants:
          (map['participants'] as List<dynamic>?)
              ?.map((p) => GameParticipantResult.fromJson(p))
              .toList() ??
          [],
    );
  }
}

/// 게임 참여자 개인별 결과
class GameParticipantResult {
  final String userId;
  final String nickname;
  final String team; // 'police', 'thief'
  final bool isWinner;
  final int score; // 기여도 점수 (나중에 로직 구체화)
  final bool isMvp;

  GameParticipantResult({
    required this.userId,
    required this.nickname,
    required this.team,
    required this.isWinner,
    this.score = 0,
    this.isMvp = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nickname': nickname,
      'team': team,
      'is_winner': isWinner,
      'score': score,
      'is_mvp': isMvp,
    };
  }

  factory GameParticipantResult.fromJson(Map<String, dynamic> map) {
    return GameParticipantResult(
      userId: map['user_id'] ?? '',
      nickname: map['nickname'] ?? 'Unknown',
      team: map['team'] ?? 'unassigned',
      isWinner: map['is_winner'] ?? false,
      score: map['score'] ?? 0,
      isMvp: map['is_mvp'] ?? false,
    );
  }
}
