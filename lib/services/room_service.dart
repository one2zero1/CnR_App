import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
    required GameSettings settings,
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
  static const String _baseUrl = 'https://cops-and-robbers-58c98.web.app';

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
      final response = await http.get(Uri.parse('$_baseUrl/rooms/$roomId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
    required GameSettings settings,
  }) async {
    final body = {"host_id": hostId, ...settings.toJson()};

    final response = await http.post(
      Uri.parse('$_baseUrl/rooms/create'),
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
      Uri.parse('$_baseUrl/rooms/join'),
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

  @override
  Future<void> updateMyStatus({
    required String roomId,
    required String uid,
    TeamRole? team,
    bool? isReady,
  }) async {
    // 3. Select Team
    if (team != null) {
      await http.post(
        Uri.parse('$_baseUrl/rooms/$roomId/team'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": uid,
          "team": team.name, // "police" or "thief"
        }),
      );
    }

    // 4. Toggle Ready
    if (isReady != null) {
      await http.post(
        Uri.parse('$_baseUrl/rooms/$roomId/ready'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": uid, "ready": isReady}),
      );
    }

    // Trigger immediate refresh
    _fetchRoomStatus(roomId);
  }

  @override
  Future<void> startGame(String roomId) async {
    // 5. Start Game
    // We need host_id, but the signature doesn't provide it.
    // We might need to store it or pass it.
    // For now, attempting without it or getting from local state?
    // Request Body: { "user_id": "user123" }

    final room = _lastKnownState[roomId];
    if (room == null) throw Exception('Room state unknown');

    final response = await http.post(
      Uri.parse('$_baseUrl/rooms/$roomId/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": room.hostId, // Using stored hostId
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start game: ${response.body}');
    }
  }

  @override
  Future<void> leaveRoom(String roomId, String uid) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/rooms/$roomId/leave'),
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
