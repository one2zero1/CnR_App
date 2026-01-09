import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import '../config/env_config.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/game_types.dart';

class RoomCreationResult {
  final String roomId;
  final String pinCode;
  RoomCreationResult({required this.roomId, required this.pinCode});
}

abstract class RoomService {
  Future<RoomCreationResult> createRoom({
    required String hostId,
    required GameSystemRules rules,
  });
  Future<String> joinRoom({required String pinCode, required UserModel user});
  Stream<RoomModel> getRoomStream(String roomId);
  Future<void> updateMyStatus({
    required String roomId,
    required String uid,
    TeamRole? team,
    bool? isReady,
  });
  Future<void> startGame(String roomId);
  Future<void> leaveRoom(String roomId, String uid);
}

class FirebaseRoomService implements RoomService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final Map<String, RoomModel> _lastKnownState = {};

  // Cache stream controllers to allow multiple listeners if needed (though typically one screen listens)
  // and to manage Firebase listener subscriptions.
  final Map<String, StreamSubscription<DatabaseEvent>> _firebaseSubscriptions =
      {};
  final Map<String, StreamController<RoomModel>> _roomControllers = {};

  StreamController<RoomModel> _getController(String roomId) {
    if (!_roomControllers.containsKey(roomId)) {
      _roomControllers[roomId] = StreamController<RoomModel>.broadcast(
        onListen: () => _startListening(roomId),
        onCancel: () => _stopListening(roomId),
      );
    }
    return _roomControllers[roomId]!;
  }

  void _startListening(String roomId) {
    if (_firebaseSubscriptions.containsKey(roomId)) return;

    final ref = _db.ref('rooms/$roomId');
    _firebaseSubscriptions[roomId] = ref.onValue.listen(
      (event) {
        if (event.snapshot.value != null) {
          try {
            // Firebase RTDB returns LinkedHashMap/Map, need appropriate casting
            // JSON structure in DB should match what fromMap expects
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);

            // Debugging log (optional, remove in production)
            // print('DEBUG: Room update for $roomId: ${data['session_info']['status']}');

            final room = RoomModel.fromMap(roomId, data);
            _lastKnownState[roomId] = room;

            if (_roomControllers.containsKey(roomId) &&
                !_roomControllers[roomId]!.isClosed) {
              _roomControllers[roomId]!.add(room);
            }
          } catch (e) {
            print('Error parsing room data for $roomId: $e');
          }
        }
      },
      onError: (error) {
        print('Firebase listener error for room $roomId: $error');
      },
    );
  }

  void _stopListening(String roomId) {
    _firebaseSubscriptions[roomId]?.cancel();
    _firebaseSubscriptions.remove(roomId);
    // We don't necessarily close the controller here as it might be listened to again
    // But usually onCancel means no one is listening.
  }

  // --- HTTP Actions (Write) ---

  @override
  Future<RoomCreationResult> createRoom({
    required String hostId,
    required GameSystemRules rules,
  }) async {
    final body = {
      "host_id": hostId,
      "game_duration_sec": rules.gameDurationSec,
      "min_players": rules.minPlayers,
      "max_players": rules.maxPlayers,
      "police_count": rules.policeCount,
      "role_assignment_mode": rules.roleAssignmentMode,

      // Activity Boundary
      "center_lat": rules.activityBoundary.centerLat,
      "center_lng": rules.activityBoundary.centerLng,
      "radius_meter": rules.activityBoundary.radiusMeter,
      "alert_on_exit": rules.activityBoundary.alertOnExit,

      // Prison Location
      "prison_lat": rules.prisonLocation.lat,
      "prison_lng": rules.prisonLocation.lng,
      "prison_radius_meter": rules.prisonLocation.radiusMeter,

      // Location Policy
      "reveal_mode": rules.locationPolicy.revealMode,
      "reveal_interval_sec": rules.locationPolicy.revealIntervalSec,
      "is_gps_high_accuracy": rules.locationPolicy.isGpsHighAccuracy,
      "police_can_see_thieves": rules.locationPolicy.policeCanSeeThieves,
      "thieves_can_see_police": rules.locationPolicy.thievesCanSeePolice,

      // Capture Rules
      "capture_distance_meter": rules.captureRules.triggerDistanceMeter,
      "require_button_press": rules.captureRules.requireButtonPress,
      "capture_cooldown_sec": rules.captureRules.captureCooldownSec,

      // Release Rules
      "release_distance_meter": rules.releaseRules.triggerDistanceMeter,
      "release_duration_sec": rules.releaseRules.releaseDurationSec,
      "interruptible": rules.releaseRules.interruptible,
      "interrupt_distance_meter": rules.releaseRules.interruptDistanceMeter,
    };

    final response = await http.post(
      Uri.parse('${EnvConfig.apiUrl}/rooms/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RoomCreationResult(
        roomId: data['room_id'],
        pinCode: data['pin_code'],
      );
    } else {
      throw Exception(
        'Failed to create room: ${response.statusCode} ${response.body}',
      );
    }
  }

  @override
  Future<String> joinRoom({
    required String pinCode,
    required UserModel user,
  }) async {
    final response = await http.post(
      Uri.parse('${EnvConfig.apiUrl}/rooms/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "pin_code": pinCode,
        "user_id": user.uid,
        "nickname": user.nickname,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final realRoomId = data['room_id'];

      // We don't get the full room state here usually, or if we do, we can push it.
      // But purely relying on the listener is safer for consistency.
      // However, to speed up initial UI, if data contains full room, we could use it.
      // Let's rely on the stream picking it up quickly.
      _startListening(realRoomId);

      return realRoomId;
    } else {
      throw Exception(
        'Failed to join room: ${response.statusCode} ${response.body}',
      );
    }
  }

  @override
  Stream<RoomModel> getRoomStream(String roomId) {
    return _getController(roomId).stream;
  }

  Future<void> selectTeam(String roomId, String uid, TeamRole team) async {
    final response = await http.post(
      Uri.parse('${EnvConfig.apiUrl}/rooms/$roomId/team'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": uid, "team": team.name}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to select team: ${response.statusCode}');
    }
  }

  Future<void> toggleReady(String roomId, String uid, bool isReady) async {
    final response = await http.post(
      Uri.parse('${EnvConfig.apiUrl}/rooms/$roomId/ready'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": uid, "ready": isReady}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to toggle ready: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateMyStatus({
    required String roomId,
    required String uid,
    TeamRole? team,
    bool? isReady,
  }) async {
    // Actions are still HTTP because clients generally don't have permission to write to /rooms/{roomId} directly
    // unless granular rules are set up. Following the plan to keep writes via API.
    if (team != null) await selectTeam(roomId, uid, team);
    if (isReady != null) await toggleReady(roomId, uid, isReady);
  }

  @override
  Future<void> startGame(String roomId) async {
    final room = _lastKnownState[roomId];
    if (room == null) throw Exception('Room state unknown');

    final response = await http.post(
      Uri.parse('${EnvConfig.apiUrl}/rooms/$roomId/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": room.sessionInfo.hostId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start game: ${response.body}');
    }
  }

  @override
  Future<void> leaveRoom(String roomId, String uid) async {
    final response = await http.delete(
      Uri.parse('${EnvConfig.apiUrl}/rooms/$roomId/leave'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": uid}),
    );

    if (response.statusCode == 200) {
      _stopListening(roomId);
      _roomControllers[roomId]?.close();
      _roomControllers.remove(roomId);
    }
  }
}
