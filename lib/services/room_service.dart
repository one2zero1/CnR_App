import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
    required GameSystemRules rules, // Changed from settings
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

class HttpRoomService implements RoomService {
  // Polling management
  final Map<String, Timer> _pollTimers = {};
  final Map<String, StreamController<RoomModel>> _roomControllers = {};
  final Map<String, RoomModel> _lastKnownState = {};

  StreamController<RoomModel> _getController(String roomId) {
    if (!_roomControllers.containsKey(roomId)) {
      _roomControllers[roomId] = StreamController<RoomModel>.broadcast(
        onListen: () => _startPolling(roomId),
        onCancel: () => _stopPolling(roomId),
      );
    }
    return _roomControllers[roomId]!;
  }

  void _startPolling(String roomId) {
    if (_pollTimers.containsKey(roomId)) return;
    _fetchRoomStatus(roomId);
    _pollTimers[roomId] = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchRoomStatus(roomId);
    });
  }

  void _stopPolling(String roomId) {
    _pollTimers[roomId]?.cancel();
    _pollTimers.remove(roomId);
  }

  Future<void> _fetchRoomStatus(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('${EnvConfig.apiUrl}/rooms/$roomId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          'DEBUG: RoomService fetchRoomStatus $roomId raw data: $data',
        ); // Debug Log
        final room = RoomModel.fromMap(roomId, data);
        _lastKnownState[roomId] = room;
        if (!_roomControllers[roomId]!.isClosed) {
          _roomControllers[roomId]!.add(room);
        }
      }
    } catch (e) {
      print('Error polling room $roomId: $e');
    }
  }

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

      // Victory conditions are currently hardcoded in backend handler defaults or not fully exposed in flat params yet,
      // but let's check if we should send them.
      // Backend handler doesn't seem to read victory conditions from individual fields,
      // it constructs it with defaults: policeWin: 'all_thieves_captured', thiefWin: 'survive_until_time_ends'.
      // So we can omit them for now as per the handler code I saw.
    };
    print(
      "===================================================create ROOM===========================\n $body",
    );
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
      final room = RoomModel.fromMap(realRoomId, data);

      _lastKnownState[realRoomId] = room;
      _getController(realRoomId).add(room);
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
      body: jsonEncode({
        "user_id": uid,
        "team": team.name, // "police" or "thief"
      }),
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
    if (team != null) await selectTeam(roomId, uid, team);
    if (isReady != null) await toggleReady(roomId, uid, isReady);
    _fetchRoomStatus(roomId);
  }

  @override
  Future<void> startGame(String roomId) async {
    final room = _lastKnownState[roomId];
    // Need host ID, assume we have it or user ID matches logic in backend
    // For now try using room.hostId if available, or current user from auth if injected (RoomService doesn't have Auth injected yet, maybe should?)
    // The API requires "user_id" which should be the host's ID.
    // Ideally RoomService should know the current user or receive it.
    // For now, let's assume the caller will ensure this or we use what we have.
    // Update interface to accept uid might be better, but staying with interface:
    // We will just use room.hostId.
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
      _stopPolling(roomId);
      _roomControllers[roomId]?.close();
      _roomControllers.remove(roomId);
    }
  }
}
