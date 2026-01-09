# Direct Location Sync 구현 완료 (Walkthrough)

Direct Location Sync 가이드에 따라 `GamePlayService`를 리팩토링하고 클라이언트 측 로직을 강화했습니다.

## 주요 변경 사항

### 1. Firebase 설정 및 의존성 추가
- `pubspec.yaml`: `firebase_core`, `firebase_database` 추가.
- `main.dart`: `Firebase.initializeApp()` 호출 추가 (Native Config 사용).

### 2. GamePlayService 리팩토링 (`lib/services/game_play_service.dart`)
- **기존 Polling 제거**: 1초마다 서버에 위치를 요청하던 `Timer` 및 HTTP 요청 로직을 제거했습니다.
- **Firebase Direct Write**: `updateMyLocation` 함수가 이제 Firebase RTDB의 `live_status/$roomId/$uid/pos` 경로에 직접 데이터를 씁니다.
- **Firebase Listener**: `getLiveStatusesStream` 함수가 `live_status/$roomId` 경로를 구독(`onValue`)하여 실시간으로 위치 업데이트를 수신합니다.
- **Role Mapping**: `RoomService`를 주입받아, 위치 데이터와 사용자 역할(Role) 정보를 병합하여 UI에 올바른 마커 색상을 표시하도록 개선했습니다.
- **Legacy Support**: `capture`, `rescue` 기능은 여전히 서버 API를 사용하므로 해당 로직은 유지(Inline)했습니다.

### 3. 클라이언트 측 경계 확인 (`lib/screens/game_play_screen.dart`)
- **Server Dependency 제거**: 더 이상 `checkBoundary` API를 호출하지 않습니다.
- **Local Calculation**: `latlong2` 패키지를 사용하여 현재 위치와 작전 구역 중심점 간의 거리를 단말기에서 직접 계산합니다.
- **Warning**: 구역 이탈 시 `SnackBar` 경고가 즉시 표시됩니다.

## 검증 방법
1. **앱 실행**: `Firebase.initializeApp()` 오류 없이 앱이 실행되는지 확인합니다.
2. **게임 진입**: 방 생성 또는 입장 후 게임 화면으로 이동합니다.
3. **위치 공유**:
    - 내 위치 이동 시 Firebase Console의 `live_status` 노드에 데이터가 갱신되는지 확인합니다.
    - 다른 플레이어 이동 시 지도상의 마커가 실시간으로 움직이는지 확인합니다.
4. **경계 이탈**: 작전 구역 밖으로 이동(가상 GPS 등 활용) 시 경고 메시지가 뜨는지 확인합니다.

> **Note**: `google-services.json` (Android) 또는 `GoogleService-Info.plist` (iOS) 파일이 프로젝트에 포함되어 있어야 정상 작동합니다.
