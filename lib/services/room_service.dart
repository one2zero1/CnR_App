import 'dart:async';
import 'dart:math';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/game_types.dart';

abstract class RoomService {
  Future<String> createRoom({
    required String hostId,
    required GameSettings settings,
  });
  Future<void> joinRoom({required String roomId, required UserModel user});
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

class MockRoomService implements RoomService {
  final Map<String, RoomModel> _rooms = {}; // Mock DB
  final _roomControllers = <String, StreamController<RoomModel>>{};

  StreamController<RoomModel> _getController(String roomId) {
    if (!_roomControllers.containsKey(roomId)) {
      _roomControllers[roomId] = StreamController<RoomModel>.broadcast();
    }
    return _roomControllers[roomId]!;
  }

  void _notify(String roomId) {
    if (_rooms.containsKey(roomId)) {
      _getController(roomId).add(_rooms[roomId]!);
    }
  }

  @override
  Future<String> createRoom({
    required String hostId,
    required GameSettings settings,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final roomId = (100000 + Random().nextInt(900000)).toString(); // 6자리 랜덤 PIN

    final newRoom = RoomModel(
      roomId: roomId,
      hostId: hostId,
      pinCode: roomId,
      status: RoomStatus.waiting,
      settings: settings,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      participants: {},
    );

    _rooms[roomId] = newRoom;
    return roomId;
  }

  @override
  Future<void> joinRoom({
    required String roomId,
    required UserModel user,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_rooms.containsKey(roomId)) throw Exception('Room not found');

    final room = _rooms[roomId]!;
    final updatedParticipants = Map<String, ParticipantInfo>.from(
      room.participants,
    );

    updatedParticipants[user.uid] = ParticipantInfo(
      nickname: user.nickname,
      team: TeamRole.unassigned,
      isReady: false,
    );

    _rooms[roomId] = RoomModel(
      roomId: room.roomId,
      hostId: room.hostId,
      pinCode: room.pinCode,
      status: room.status,
      settings: room.settings,
      expiresAt: room.expiresAt,
      participants: updatedParticipants,
    );
    _notify(roomId);
  }

  @override
  Stream<RoomModel> getRoomStream(String roomId) {
    if (_rooms.containsKey(roomId)) {
      Future.delayed(Duration.zero, () => _notify(roomId)); // 초기값 전송
    }
    return _getController(roomId).stream;
  }

  @override
  Future<void> updateMyStatus({
    required String roomId,
    required String uid,
    TeamRole? team,
    bool? isReady,
  }) async {
    if (!_rooms.containsKey(roomId)) return;
    final room = _rooms[roomId]!;
    final participants = room.participants;

    if (participants.containsKey(uid)) {
      final oldInfo = participants[uid]!;
      participants[uid] = ParticipantInfo(
        nickname: oldInfo.nickname,
        team: team ?? oldInfo.team,
        isReady: isReady ?? oldInfo.isReady,
      );
      _notify(roomId);
    }
  }

  @override
  Future<void> startGame(String roomId) async {
    // room status update
  }

  @override
  Future<void> leaveRoom(String roomId, String uid) async {
    if (_rooms.containsKey(roomId)) {
      _rooms[roomId]!.participants.remove(uid);
      _notify(roomId);
    }
  }
}
