import 'package:latlong2/latlong.dart';
import 'game_types.dart';

class LocationUpdateModel {
  final String userId;
  final double lat;
  final double lng;
  final int timestamp;

  LocationUpdateModel({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'lat': lat, 'lng': lng, 'timestamp': timestamp};
  }
}

class PlayerLocationModel {
  final String userId;
  final LatLng position;
  final TeamRole role;
  final bool isCaptured;

  PlayerLocationModel({
    required this.userId,
    required this.position,
    required this.role,
    required this.isCaptured,
  });

  factory PlayerLocationModel.fromJson(Map<String, dynamic> json) {
    final state = json['state'] as Map<String, dynamic>? ?? {};
    return PlayerLocationModel(
      userId: json['user_id'] ?? '',
      position: LatLng(
        (json['lat'] ?? 0.0).toDouble(),
        (json['lng'] ?? 0.0).toDouble(),
      ),
      role: TeamRole.values.firstWhere(
        (e) => e.name == (json['role'] ?? 'unassigned'),
        orElse: () => TeamRole.unassigned,
      ),
      isCaptured: state['is_captured'] ?? false,
    );
  }
}

class BoundaryCheckResponse {
  final bool isWithinBoundary;
  final double distanceFromCenter;

  BoundaryCheckResponse({
    required this.isWithinBoundary,
    required this.distanceFromCenter,
  });

  factory BoundaryCheckResponse.fromJson(Map<String, dynamic> json) {
    return BoundaryCheckResponse(
      isWithinBoundary: json['is_within_boundary'] ?? true,
      distanceFromCenter: (json['distance_from_center'] ?? 0.0).toDouble(),
    );
  }
}
