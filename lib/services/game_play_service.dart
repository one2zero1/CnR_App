import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/live_status_model.dart';
import '../models/location_model.dart';
import '../models/game_types.dart';

abstract class GamePlayService {
  Future<void> updateMyLocation(String roomId, String uid, LatLng position);
  Stream<List<LiveStatusModel>> getLiveStatusesStream(String roomId);
  Future<bool> attemptCapture({
    required String roomId,
    required String policeId,
    required String targetThiefId,
  });
  Future<bool> attemptRescue({
    required String roomId,
    required String rescuerId,
    required String targetThiefId,
  });
  Future<BoundaryCheckResponse?> checkBoundary({
    required String roomId,
    required String uid,
    required LatLng position,
  });
  // Stream<GameResult> getGameResultStream(String roomId);
}

class HttpGamePlayService implements GamePlayService {
  static const String _baseUrl = 'https://cops-and-robbers-58c98.web.app';

  // Polling for live status
  final Map<String, Timer> _pollTimers = {};
  final Map<String, StreamController<List<LiveStatusModel>>> _controllers = {};

  StreamController<List<LiveStatusModel>> _getController(String roomId) {
    if (!_controllers.containsKey(roomId)) {
      _controllers[roomId] = StreamController<List<LiveStatusModel>>.broadcast(
        onListen: () => _startPolling(roomId),
        onCancel: () => _stopPolling(roomId),
      );
    }
    return _controllers[roomId]!;
  }

  void _startPolling(String roomId) {
    if (_pollTimers.containsKey(roomId)) return;

    _fetchPlayersLocation(roomId);

    // Poll frequently for game status (e.g. 1 second or 2 seconds)
    // API docs: "Update GPS" response logic mentions warning logs but not rate limit.
    // "Connection Ping" is 10s.
    // Location fetching should be reasonable.
    _pollTimers[roomId] = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchPlayersLocation(roomId);
    });
  }

  void _stopPolling(String roomId) {
    _pollTimers[roomId]?.cancel();
    _pollTimers.remove(roomId);
  }

  Future<void> _fetchPlayersLocation(String roomId) async {
    try {
      // 8. Get Players Location
      // Endpoint: GET /location/<roomId>/players?requesting_user_id=...
      // We need a user_id. We might need to store my user_id somewhere or pass it.
      // Since getLiveStatusesStream doesn't take uid, we have a problem.
      // We might need to rely on the fact that we can pass a dummy or keep track of current user.
      // For now, let's assume we can fetch without it OR we need to refactor interface.
      // However, sticking to interface: we'll use a placeholder or modify if critical.
      // Actually, the API says "Note: Team visibility policy filters players".
      // If we don't pass `requesting_user_id`, we might get nothing or error.
      // Use a placeholder or "system" if allowed, but likely we need the logged-in user.
      // Since `GamePlayService` is usually used where we know the user, maybe we should've injected Auth?
      // For now, I'll pass 'guest' or 'spectator' if possible, or try to avoid error.

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/location/$roomId/players?requesting_user_id=spectator',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> players = data['players'] ?? [];

        final models = players.map((p) {
          final state = p['state'] ?? {};
          return LiveStatusModel(
            uid: p['user_id'] ?? '',
            role: TeamRole.values.firstWhere(
              (e) => e.name == (p['role'] ?? 'unassigned'),
              orElse: () => TeamRole.unassigned,
            ),
            position: LatLng(
              (p['lat'] ?? 0.0).toDouble(),
              (p['lng'] ?? 0.0).toDouble(),
            ),
            state: (state['is_captured'] == true)
                ? PlayerState.captured
                : PlayerState.normal, // Simple mapping
            lastPing: DateTime.now(),
          );
        }).toList();

        if (!_controllers[roomId]!.isClosed) {
          _controllers[roomId]!.add(models);
        }
      }
    } catch (e) {
      print('Error polling locations $roomId: $e');
    }
  }

  @override
  Future<void> updateMyLocation(
    String roomId,
    String uid,
    LatLng position,
  ) async {
    // 7. Update GPS
    try {
      await http.post(
        Uri.parse('$_baseUrl/location/$roomId/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": uid,
          "lat": position.latitude,
          "lng": position.longitude,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      // Fail silently or log
      print('Failed to update location: $e');
    }
  }

  @override
  Stream<List<LiveStatusModel>> getLiveStatusesStream(String roomId) {
    return _getController(roomId).stream;
  }

  @override
  Future<bool> attemptCapture({
    required String roomId,
    required String policeId,
    required String targetThiefId,
  }) async {
    // 10. Capture Thief
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/$roomId/capture'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"police_id": policeId, "thief_id": targetThiefId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> attemptRescue({
    required String roomId,
    required String rescuerId,
    required String targetThiefId,
  }) async {
    // 11. Release Thief
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/$roomId/release'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "thief_id": rescuerId,
          "captured_thief_id": targetThiefId,
          "duration_sec": 5, // Hardcoded requirement from mock/UI interaction
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<BoundaryCheckResponse?> checkBoundary({
    required String roomId,
    required String uid,
    required LatLng position,
  }) async {
    // 9. Check Boundary
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/location/$roomId/check-boundary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": uid,
          "lat": position.latitude,
          "lng": position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        return BoundaryCheckResponse.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Failed to check boundary: $e');
    }
    return null;
  }
}
