import 'package:latlong2/latlong.dart';
import 'game_types.dart';

class LiveStatusModel {
  final String uid;
  final TeamRole role;
  final LatLng position;
  final PlayerState state;
  final DateTime lastPing;

  LiveStatusModel({
    required this.uid,
    required this.role,
    required this.position,
    required this.state,
    required this.lastPing,
  });

  factory LiveStatusModel.fromMap(String userId, Map<String, dynamic> data) {
    final pos = data['pos'] ?? {};
    final stateInfo = data['state'] ?? {};

    // PlayerState 판단 로직
    PlayerState playerState = PlayerState.normal;
    if (stateInfo['is_captured'] == true) playerState = PlayerState.captured;
    if (stateInfo['is_released'] == true) playerState = PlayerState.released;

    return LiveStatusModel(
      uid: userId,
      role: TeamRole.values.firstWhere(
        (e) => e.name == (data['role'] ?? 'thief'),
        orElse: () => TeamRole.thief,
      ),
      position: LatLng(
        (pos['lat'] ?? 0.0).toDouble(),
        (pos['lng'] ?? 0.0).toDouble(),
      ),
      state: playerState,
      lastPing: DateTime.now(), // Timestamp 처리 필요
    );
  }
}
