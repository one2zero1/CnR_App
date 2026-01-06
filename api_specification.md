# 📄 API Specification & Service Interfaces

이 문서는 Flutter 클라이언트가 백엔드(Firebase)와 통신하기 위한 데이터 모델 및 서비스 인터페이스 명세를 정의합니다.

---

## 1. Data Models (JSON / Dart Classes)

### 1.1 User (`UserModel`)
사용자 기본 정보
```dart
class UserModel {
  final String uid;
  final String nickname;
  final String? profileImg;
  final int mannerPoint;
  final UserStats stats;

  // JSON serialization methods...
}
```

### 1.2 Room (`RoomModel`)
게임 대기 및 설정 정보 (Firestore / Realtime DB)
```dart
class RoomModel {
  final String roomId;
  final String hostId;
  final String pinCode;
  final RoomStatus status; // waiting, playing, ended
  final GameSettings settings;
  final DateTime expiresAt;
  
  // Participants map: uid -> ParticipantInfo
  final Map<String, ParticipantInfo> participants;
}
```

### 1.3 ParticipantInfo
방에 참여한 유저의 상태
```dart
class ParticipantInfo {
  final String nickname;
  final TeamRole team; // police, thief, unassigned
  final bool isReady;
  final bool isHost;
}
```

### 1.4 LiveGameStatus (`LiveStatusModel`)
게임 중 실시간 플레이어 상태 (위치 포함)
```dart
class LiveStatusModel {
  final String uid;
  final TeamRole role;
  final LatLng position; // {lat, lng}
  final PlayerState state; // normal, captured, released
  final DateTime lastPing;
}
```

---

## 2. Service Interfaces (Dart)

클라이언트 앱은 아래의 인터페이스를 통해 백엔드 로직을 수행합니다. 초기 개발 단계에서는 이 인터페이스의 `Mock` 구현체를 사용하고, 추후 `Firebase` 구현체로 교체합니다.

### 2.1 AuthService
인증 관련 기능
```dart
abstract class AuthService {
  // 익명 로그인 또는 기기 ID 로그인
  Future<UserModel> signInAnonymously(String nickname);
  
  // 로그아웃
  Future<void> signOut();
  
  // 현재 유저 정보 스트림
  Stream<UserModel?> get userStream;
}
```

### 2.2 RoomService
방 생성, 입장, 관리 기능 (Realtime DB `rooms` 노드 제어)
```dart
abstract class RoomService {
  // 방 생성
  Future<String> createRoom({required String hostId, required GameSettings settings});
  
  // 방 입장 (PIN 코드로)
  Future<void> joinRoom({required String roomId, required UserModel user});
  
  // 방 실시간 정보 구독
  Stream<RoomModel> getRoomStream(String roomId);
  
  // 팀 변경 / 준비 상태 변경
  Future<void> updateMyStatus({required String roomId, required String uid, TeamRole? team, bool? isReady});
  
  // 게임 시작 (호스트 전용)
  Future<void> startGame(String roomId);
  
  // 방 나가기
  Future<void> leaveRoom(String roomId, String uid);
}
```

### 2.3 GamePlayService
게임 중 실시간 로직 (위치 공유, 잡기/구출 등)
```dart
abstract class GamePlayService {
  // 내 위치 전송 (주기적 호출)
  Future<void> updateMyLocation(String roomId, String uid, LatLng position);
  
  // 다른 플레이어들의 실시간 상태(위치 포함) 구독
  Stream<List<LiveStatusModel>> getLiveStatusesStream(String roomId);
  
  // 검거 시도 (경찰 -> 도둑)
  Future<bool> attemptCapture({required String roomId, required String policeId, required String targetThiefId});
  
  // 구출 시도 (도둑 -> 도둑)
  Future<bool> attemptRescue({required String roomId, required String rescuerId, required String targetThiefId});
  
  // 게임 종료 스트림 (승패 판정)
  Stream<GameResult> getGameResultStream(String roomId); // 실제로는 Room status 변화 감지
}
```

---

## 3. Firebase Paths Reference

- **Users**: `collection('users').doc(uid)`
- **Game History**: `collection('game_history').doc(gameId)`
- **Realtime Rooms**: `ref('rooms/{roomId}')`
- **Realtime Live Status**: `ref('live_status/{roomId}/{uid}')`
