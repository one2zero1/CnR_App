import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import '../config/env_config.dart';
import 'auth_service.dart';
import 'room_service.dart';
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

class FirebaseGamePlayService implements GamePlayService {
  final AuthService? authService;
  final RoomService? roomService;
  final _logger = Logger();

  FirebaseGamePlayService({this.authService, this.roomService});

  // Role cache
  final Map<String, TeamRole> _roleCache = {};
  StreamSubscription? _roomSubscription;

  void _ensureRoleCache(String roomId) {
    if (_roleCache.isNotEmpty) return;
    if (roomService == null) return;

    // Listen to room updates to keep roles fresh
    _roomSubscription?.cancel();
    _roomSubscription = roomService!.getRoomStream(roomId).listen((room) {
      for (var entry in room.participants.entries) {
        final uid = entry.key;
        final roleStr = entry.value.team;
        _roleCache[uid] = TeamRole.values.firstWhere(
          (e) => e.name == roleStr,
          orElse: () => TeamRole.unassigned,
        );
      }
    });
  }

  @override
  Future<void> updateMyLocation(
    String roomId,
    String uid,
    LatLng position,
  ) async {
    try {
      final ref = FirebaseDatabase.instance.ref('live_status/$roomId/$uid/pos');
      await ref.set({
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      _logger.e('Firebase update failed', error: e);
    }
  }

  @override
  Stream<List<LiveStatusModel>> getLiveStatusesStream(String roomId) {
    _ensureRoleCache(roomId);

    final ref = FirebaseDatabase.instance.ref('live_status/$roomId');
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<dynamic, dynamic> playersMap = data as Map<dynamic, dynamic>;
      final List<LiveStatusModel> result = [];

      playersMap.forEach((key, value) {
        final uid = key.toString();
        final playerRole = _roleCache[uid] ?? TeamRole.unassigned;

        // Data structure: {pos: {lat, lng, timestamp}, state: {...}?}
        // If value has 'pos', use it. Else assume value is pos if structure is flat (it shouldn't be based on set)
        final valMap = Map<String, dynamic>.from(value as Map);
        final posMap = valMap['pos'] as Map?;

        if (posMap != null) {
          final lat = (posMap['lat'] as num?)?.toDouble() ?? 0.0;
          final lng = (posMap['lng'] as num?)?.toDouble() ?? 0.0;

          // TODO: 'state' (captured) might need to come from elsewhere if not in live_status
          // For now, assume default normal unless we find a 'state' node
          final stateMap = valMap['state'] as Map?;
          final isCaptured = stateMap?['is_captured'] == true;

          result.add(
            LiveStatusModel(
              uid: uid,
              role: playerRole,
              position: LatLng(lat, lng),
              state: isCaptured ? PlayerState.captured : PlayerState.normal,
              lastPing: DateTime.now(), // Realtime
            ),
          );
        }
      });

      return result;
    });
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
    return null;
  }
}
