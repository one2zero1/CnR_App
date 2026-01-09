/// GPS 위치 정보 모델
class LocationModel {
  final double lat;
  final double lng;
  final DateTime timestamp;

  LocationModel({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  /// Realtime DB 데이터를 LocationModel로 변환
  factory LocationModel.fromRealtimeDB(Map<String, dynamic> data) {
    return LocationModel(
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      timestamp: DateTime.now(), // timestamp가 DB에 없다면 현재 시간 사용
    );
  }

  /// LocationModel을 Realtime DB 데이터로 변환
  Map<String, dynamic> toRealtimeDB() {
    return {'lat': lat, 'lng': lng};
  }
}

class BoundaryCheckResponse {
  final bool isWithinBoundary;
  final double distanceToCenter;
  final String? warningMessage;

  BoundaryCheckResponse({
    required this.isWithinBoundary,
    required this.distanceToCenter,
    this.warningMessage,
  });

  factory BoundaryCheckResponse.fromJson(Map<String, dynamic> json) {
    return BoundaryCheckResponse(
      isWithinBoundary: json['is_within_boundary'] ?? false,
      distanceToCenter: (json['distance_to_center'] ?? 0.0).toDouble(),
      warningMessage: json['warning_message'],
    );
  }
}
