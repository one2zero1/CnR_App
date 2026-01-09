class UserModel {
  final String uid;
  final String nickname;
  final String? profileImg;
  final int mannerPoint;

  // Police stats
  final int policeWins;
  final int policeGamesPlayed;

  // Thief stats
  final int thiefWins;
  final int thiefGamesPlayed;

  // Report history
  final int reportedCount;
  final int praisedCount;

  // Activity stats
  final double totalDistance;

  UserModel({
    required this.uid,
    required this.nickname,
    this.profileImg,
    this.mannerPoint = 0,
    this.policeWins = 0,
    this.policeGamesPlayed = 0,
    this.thiefWins = 0,
    this.thiefGamesPlayed = 0,
    this.reportedCount = 0,
    this.praisedCount = 0,
    this.totalDistance = 0.0,
  });

  /// Firestore 문서를 UserModel로 변환
  factory UserModel.fromJson(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String? ?? '',
      nickname: data['nickname'] as String? ?? '',
      profileImg: data['profile_img'] as String?,
      mannerPoint: data['manner_point'] as int? ?? 0,
      policeWins: data['police_wins'] as int? ?? 0,
      policeGamesPlayed: data['police_games_played'] as int? ?? 0,
      thiefWins: data['thief_wins'] as int? ?? 0,
      thiefGamesPlayed: data['thief_games_played'] as int? ?? 0,
      reportedCount: data['reported_count'] as int? ?? 0,
      praisedCount: data['praised_count'] as int? ?? 0,
      totalDistance: (data['total_distance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// UserModel을 Firestore 문서로 변환
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'profile_img': profileImg,
      'manner_point': mannerPoint,
      'police_wins': policeWins,
      'police_games_played': policeGamesPlayed,
      'thief_wins': thiefWins,
      'thief_games_played': thiefGamesPlayed,
      'reported_count': reportedCount,
      'praised_count': praisedCount,
      'total_distance': totalDistance,
    };
  }

  /// 경찰 승률 계산
  double get policeWinRate {
    if (policeGamesPlayed == 0) return 0.0;
    return policeWins / policeGamesPlayed;
  }

  /// 도둑 승률 계산
  double get thiefWinRate {
    if (thiefGamesPlayed == 0) return 0.0;
    return thiefWins / thiefGamesPlayed;
  }

  /// 전체 게임 플레이 횟수
  int get totalGamesPlayed => policeGamesPlayed + thiefGamesPlayed;

  /// 전체 승리 횟수
  int get totalWins => policeWins + thiefWins;
}
