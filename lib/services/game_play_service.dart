import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../models/live_status_model.dart';
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
  // Stream<GameResult> getGameResultStream(String roomId);
}

class MockGamePlayService implements GamePlayService {
  // roomId -> List<LiveStatusModel>
  final _liveData = <String, Map<String, LiveStatusModel>>{};
  final _controllers = <String, StreamController<List<LiveStatusModel>>>{};

  @override
  Future<void> updateMyLocation(
    String roomId,
    String uid,
    LatLng position,
  ) async {
    // 실제로는 Firebas Realtime DB에 쓰기
    if (!_liveData.containsKey(roomId)) {
      _liveData[roomId] = {};
    }

    final currentData = _liveData[roomId]!;
    // 기존 데이터 유지하면서 위치만 업데이트
    TeamRole role = TeamRole.thief; // Mock default
    PlayerState state = PlayerState.normal;

    if (currentData.containsKey(uid)) {
      role = currentData[uid]!.role;
      state = currentData[uid]!.state;
    }

    currentData[uid] = LiveStatusModel(
      uid: uid,
      role: role,
      position: position,
      state: state,
      lastPing: DateTime.now(),
    );

    if (_controllers.containsKey(roomId)) {
      _controllers[roomId]!.add(currentData.values.toList());
    }
  }

  @override
  Stream<List<LiveStatusModel>> getLiveStatusesStream(String roomId) {
    if (!_controllers.containsKey(roomId)) {
      _controllers[roomId] =
          StreamController<List<LiveStatusModel>>.broadcast();
    }
    return _controllers[roomId]!.stream;
  }

  @override
  Future<bool> attemptCapture({
    required String roomId,
    required String policeId,
    required String targetThiefId,
  }) async {
    // 거리 계산 및 검증 로직 (Mock에서는 무조건 성공)
    await Future.delayed(const Duration(milliseconds: 300));

    if (_liveData.containsKey(roomId) &&
        _liveData[roomId]!.containsKey(targetThiefId)) {
      final old = _liveData[roomId]![targetThiefId]!;
      _liveData[roomId]![targetThiefId] = LiveStatusModel(
        uid: old.uid,
        role: old.role,
        position: old.position,
        state: PlayerState.captured,
        lastPing: DateTime.now(),
      );
      // Notify
      _controllers[roomId]?.add(_liveData[roomId]!.values.toList());
      return true;
    }
    return false;
  }

  @override
  Future<bool> attemptRescue({
    required String roomId,
    required String rescuerId,
    required String targetThiefId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // 무조건 성공
    if (_liveData.containsKey(roomId) &&
        _liveData[roomId]!.containsKey(targetThiefId)) {
      final old = _liveData[roomId]![targetThiefId]!;
      _liveData[roomId]![targetThiefId] = LiveStatusModel(
        uid: old.uid,
        role: old.role,
        position: old.position,
        state: PlayerState.released,
        lastPing: DateTime.now(),
      );
      _controllers[roomId]?.add(_liveData[roomId]!.values.toList());
      return true;
    }
    return false;
  }
}
