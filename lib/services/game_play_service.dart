import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/env_config.dart';
import 'auth_service.dart';
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
  final AuthService? authService;

  HttpGamePlayService({this.authService});

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

  Future<void> sendPing(String roomId, String uid) async {
    try {
      await http.post(
        Uri.parse('${EnvConfig.apiUrl}/game/$roomId/ping'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": uid}),
      );
    } catch (e) {
      print('Ping failed: $e');
    }
  }

  Future<Map<String, dynamic>?> checkGameStatus(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('${EnvConfig.apiUrl}/game/$roomId/status'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Check game status failed: $e');
    }
    return null;
  }

  void _startPolling(String roomId) {
    if (_pollTimers.containsKey(roomId)) return;

    _fetchPlayersLocation(roomId);

    _pollTimers[roomId] = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchPlayersLocation(roomId);
      // Also ping periodically if we knew the user ID here easily,
      // but typically UI calls ping or we do it here if we have authService.
      final uid = authService?.currentUser?.uid;
      if (uid != null) {
        sendPing(roomId, uid);
        // Optionally check game status here too
      }
    });
  }

  void _stopPolling(String roomId) {
    _pollTimers[roomId]?.cancel();
    _pollTimers.remove(roomId);
  }

  Future<void> _fetchPlayersLocation(String roomId) async {
    try {
      final uid = authService?.currentUser?.uid ?? 'spectator';
      final response = await http.get(
        Uri.parse(
          '${EnvConfig.apiUrl}/location/$roomId/players?requesting_user_id=$uid',
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
                : PlayerState.normal,
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
    try {
      await http.post(
        Uri.parse('${EnvConfig.apiUrl}/location/$roomId/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": uid,
          "lat": position.latitude,
          "lng": position.longitude,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
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
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.apiUrl}/game/$roomId/capture'),
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
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.apiUrl}/game/$roomId/release'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "thief_id": rescuerId,
          "captured_thief_id": targetThiefId,
          "duration_sec": 5,
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
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.apiUrl}/location/$roomId/check-boundary'),
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
