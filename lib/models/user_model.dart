class UserModel {
  final String uid;
  final String nickname;
  final String? profileImg;
  final int mannerPoint;
  final UserStats stats;

  UserModel({
    required this.uid,
    required this.nickname,
    this.profileImg,
    this.mannerPoint = 0,
    required this.stats,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      nickname: json['nickname'] ?? '',
      profileImg: json['profile_img'],
      mannerPoint: json['manner_point'] ?? 0,
      stats: UserStats.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'profile_img': profileImg,
      'manner_point': mannerPoint,
      ...stats.toJson(),
    };
  }
}

class UserStats {
  final int totalGames;
  final int policeWins;
  final int thiefWins;

  UserStats({this.totalGames = 0, this.policeWins = 0, this.thiefWins = 0});

  factory UserStats.fromJson(Map<String, dynamic> json) {
    // Firestore 구조에 따라 stats 필드가 따로 있을 수도 있고 평탄화될 수도 있음.
    // 여기서는 최상위에 police_stats 등으로 존재한다고 가정 (spec 참조)
    final pStats = json['police_stats'] ?? {};
    final tStats = json['thief_stats'] ?? {};

    // Total games 계산 로직은 서버에 있을 수 있으나 클라이언트 모델용으로 간단히
    return UserStats(
      totalGames:
          (pStats['police_games_played'] ?? 0) +
          (tStats['thief_games_played'] ?? 0),
      policeWins: pStats['police_wins'] ?? 0,
      thiefWins: tStats['thief_wins'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'police_stats': {
        'police_wins': policeWins,
        'police_games_played': totalGames, // 단순화
      },
      'thief_stats': {
        'thief_wins': thiefWins,
        'thief_games_played': totalGames, // 단순화
      },
    };
  }
}
