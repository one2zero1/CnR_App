# 경찰과 도둑 (Gyeong Do)

현실 기반 실시간 추격 게임, **경찰과 도둑** 모바일 애플리케이션입니다.
GPS 위치 기반 기술을 활용하여 사용자가 실제 공간에서 경찰과 도둑이 되어 쫓고 쫓기는 스릴 넘치는 게임 경험을 제공합니다.

---

## 1. 프로젝트 소개
**경찰과 도둑**은 전통적인 술래잡기 놀이를 모바일 기술과 접목시킨 오프라인+온라인 융합 게임입니다.
친구들과 방을 만들고, 역할을 정해 실제 지형지물을 이용하며 게임을 즐길 수 있습니다. 
실시간 위치 공유, 감옥 시스템, 제한 구역 설정 등 다양한 전략적 요소를 포함하고 있습니다.

---

## 2. 주요 기능

### ✅ 구현된 기능
*   **방 생성 및 관리 (Host)**
    *   게임 시간(10~60분), 플레이 반경(100m~1km), 위치 공개 주기 설정
    *   감옥 위치 및 사이즈 설정 (지도 상에서 직접 지정)
    *   **QR 코드 생성**: 간편한 입장을 위한 방 입장 QR 코드 제공
*   **방 입장 (Guest)**
    *   **6자리 PIN 코드** 입력을 통한 입장
    *   **QR 코드 스캔**: 카메라를 이용해 즉시 입장 가능
*   **대기실 (Lobby)**
    *   실시간 참가자 목록 확인 (Polling 방식)
    *   **역할 분담**: 경찰/도둑 선택 (수동 선택 및 낙관적 UI 적용으로 빠른 반응성 제공)
    *   준비 완료 및 게임 시작 기능
*   **게임 플레이 (In-Game)**
    *   **실시간 위치 추적**: `flutter_map`을 이용한 사용자 위치 표시
    *   **팀별 가시성 처리**: 경찰은 도둑의 위치를 주기적으로, 도둑은 경찰의 위치를 실시간으로 확인
    *   **가시성 모드 (Visibility Mode)**: 마커를 심플한 점(Dot) 형태로 표시하여 시인성 개선 및 게임 몰입도 향상 (설정에서 토글 가능)
    *   **감옥 영역 가시화**: 감옥 위치를 반투명 원형 오버레이로 표시하여 명확한 경계 제공
    *   **이탈 방지**: 설정된 반경 밖으로 나갈 경우 경고 알림 및 서버 보고
    *   **음성 채팅 (무전기)**: 팀원 간 실시간 무전 기능을 통해 전략적 소통 가능
*   **부가 기능**
    *   **튜토리얼 다시보기**: 설정 화면에서 언제든 튜토리얼 확인 가능
    *   **이용약관 및 개인정보 처리방침**: 앱 내 설정에서 법적 고지 사항 확인 가능
*   **인증 시스템**
    *   익명 로그인 (Anonymous Auth) 지원으로 빠른 게임 시작

### 🚀 구현 예정 기능
*   **백그라운드 위치 서비스**: 앱이 백그라운드에 있어도 위치 공유 유지
*   **게임 결과 화면**: 승리/패배 및 MVP 선정 화면
*   **소셜 로그인**: 구글, 카카오 등 소셜 계정 연동

---

## 3. 기술 스택 (Tech Stack)

### 📱 Frontend (Mobile App)
*   **Framework**: Flutter (Dart)
*   **State Management**: Provider
*   **Map & Location**: 
    *   `flutter_map`: OpenStreetMap 기반 지도 렌더링
    *   `latlong2`: 위경도 좌표 및 거리 계산
    *   `geolocator`: 디바이스 GPS 위치 수신
*   **Network & Async**: 
    *   `http`: REST API 통신
    *   Stream/FutureBuilder: 비동기 데이터 처리
*   **Utility**:
    *   `mobile_scanner`: QR 코드 스캔 기능
    *   `qr_flutter`: QR 코드 생성 및 렌더링
    *   `shared_preferences`: 로컬 설정 저장 (가시성 모드 등)

### 📡 Backend (Interface)
*   **Protocol**: HTTP REST API
*   **Format**: JSON
*   **Polling**: 실시간성을 위한 주기적 상태 조회 (Socket 미사용 환경 대응)

---

## 4. 프로젝트 구조 (Project Structure)

```text
lib/
├── config/             # 앱 전역 설정 (상수, 환경변수 등)
│   ├── app_strings.dart      # 문자열 상수
│   └── legal_strings.dart    # 이용약관 및 개인정보 처리방침 텍스트
├── models/             # 데이터 모델 (Json Serialization)
│   ├── room_model.dart       # 방 정보 및 참가자 모델
│   ├── user_model.dart       # 사용자 정보 모델
│   ├── location_model.dart   # 위치 업데이트 및 경계 확인 모델
│   └── game_types.dart       # Enum 및 공통 타입 정의
├── providers/          # 상태 관리 (Global State)
│   └── theme_provider.dart   # 테마 및 가시성 모드 관리
├── screens/            # UI 화면 (Pages)
│   ├── home_screen.dart        # 메인 홈
│   ├── jail_settings_screen.dart # 방 생성 및 설정
│   ├── room_created_screen.dart  # 방 생성 완료 (PIN/QR)
│   ├── join_room_screen.dart     # 방 입장 (PIN/QR 스캔)
│   ├── waiting_room_screen.dart  # 대기실 (역할 선택)
│   ├── map_preview_screen.dart   # 지도 미리보기 (게임 설정 확인)
│   ├── game_play_screen.dart     # 게임 메인 지도 화면
│   ├── settings_screen.dart      # 설정 (가시성, 튜토리얼, 약관)
│   ├── tutorial_screen.dart      # 튜토리얼 화면
│   └── common_text_screen.dart   # 공용 텍스트 뷰어 (약관 등)
├── services/           # 비즈니스 로직 및 API 통신
│   ├── auth_service.dart     # 인증 서비스
│   ├── room_service.dart     # 방 관리 API
│   └── game_play_service.dart# 게임 진행 및 위치 API
├── theme/              # 디자인 테마 (Colors, Styles)
└── widgets/            # 재사용 가능한 UI 컴포넌트
    └── flutter_map_widget.dart # 지도 및 마커 렌더링 위젯
```

---

## 5. 주요 기능 구현 로직 상세

### 1) 방 생성 및 입장 프로세스 (Room Creation & Join)
*   **패키지**: `http`, `mobile_scanner`, `qr_flutter`
*   **로직**:
    *   `RoomService`에서 `http.post`로 방 생성을 요청하고, 반환된 `pin_code`를 `RoomCreationResult` 객체로 관리합니다.
    *   입장 시 QR 코드는 `mobile_scanner`의 `MobileScannerController`를 통해 스캔되며, 중복 인식을 방지하기 위해 `NoDuplicates` 모드를 사용합니다.
```dart
// RoomService: 방 생성 요청
final response = await http.post(Uri.parse('$baseUrl/rooms/create'), ...);
return RoomCreationResult(
  roomId: data['room_id'], // API 통신용 UUID
  pinCode: data['pin_code'] // 입장용 6자리 PIN
);
```

### 2) 대기실 실시간 동기화 (Polling System)
*   **패키지**: `dart:async` (Timer, StreamController)
*   **로직**:
    *   소켓 대신 `Timer.periodic`을 사용하여 2초마다 서버 상태를 조회합니다.
    *   `StreamController.broadcast`를 사용해 여러 위젯(대기실 확인, 자동 게임 시작 감지 등)에서 동시에 상태를 구독할 수 있게 합니다.
```dart
// HttpRoomService: Polling 시작
_pollTimers[roomId] = Timer.periodic(const Duration(seconds: 2), (_) async {
  final response = await http.get(Uri.parse('$baseUrl/rooms/$roomId'));
  if (response.statusCode == 200) {
    _controller.add(RoomModel.fromMap(data)); // Stream 업데이트
  }
});
```
*   **낙관적 업데이트 (Optimistic UI)**:
    *   `WaitingRoomScreen`에서는 `setState`를 통해 로컬의 `_optimisticRoles` 상태를 먼저 변경하여 즉각적인 UI 반응을 제공합니다.

### 3) 핀(PIN) 입력 UX 개선
*   **핵심 위젯**: `Stack`, `TextField`, `Opacity`
*   **로직**:
    *   투명한 `TextField`를 상단에 배치하여 터치 이벤트를 받고, 실제 시각적 표현은 하단의 `Container` 배열(6개)이 담당합니다.
```dart
Stack(
  children: [
    Opacity(
      opacity: 0, // 보이지 않지만 입력 가능
      child: TextField(controller: _codeController, maxLength: 6),
    ),
    Row(
      children: List.generate(6, (index) => _buildDigitBox(index)),
    ),
  ],
)
```

### 4) 게임 위치 공유 및 가시성 처리
*   **패키지**: `geolocator`, `latlong2`, `flutter_map`
*   **로직**:
    *   `Geolocator`로 위치를 수집하여 서버로 전송하고, `Distance` 클래스로 반경 이탈을 체크합니다.
    *   **가시성 모드**: `ThemeProvider`의 상태(`isVisibilityMode`)에 따라 `FlutterMapWidget`에서 마커를 렌더링할 때 `Marker` 위젯의 자식(child)으로 복잡한 `Column`(아이콘+텍스트) 대신 단순한 `Container`(원형 점)를 반환합니다.
    *   **감옥 영역**: `CircleMarker`를 사용하여 지도상에 반투명한 원을 그려 시각적으로 표현합니다.

### 5) 실시간 음성 채팅 (Real-time Voice Chat)
*   **패키지**: `sound_stream`, `permission_handler`, `flutter_volume_controller`
*   **로직**:
    *   `SoundStream` 패키지를 활용하여 마이크 입력을 Raw PCM 데이터로 캡처하고, 이를 스트림 형태로 팀원들에게 전송합니다.
    *   `audio_session` 설정을 통해 통화 모드(Voice Chat)에 최적화된 오디오 경로를 구성했습니다.
    *   **볼륨 동기화**: `flutter_volume_controller`를 도입하여 앱 내 슬라이더가 아닌 기기의 물리적 볼륨 버튼으로도 음성 채팅 음량을 직관적으로 조절할 수 있도록 구현했습니다.

---

## 6. 트러블슈팅 (Troubleshooting)

### QR 코드 스캔 정확도 및 중복 인식 문제
*   **문제 상황**: 
    1.  `MobileScanner` 기본 설정 사용 시, 카메라가 프레임마다 QR 코드를 인식하여 1초에 수십 번의 중복 이벤트가 발생했습니다.
    2.  이로 인해 화면 이동(`Navigator.push`)이 여러 번 호출되거나, 잘못된 데이터 처리가 발생하는 문제가 있었습니다.
    3.  주변의 바코드나 다른 형식을 QR 코드로 오인지하는 경우도 있었습니다.
*   **해결 방법**: 
    *   `MobileScannerController`의 설정을 최적화하여 문제를 해결했습니다.
    *   `detectionSpeed`를 `noDuplicates`로 설정하여 동일한 QR 코드가 연속으로 인식되는 것을 방지했습니다.
    *   `formats`를 `BarcodeFormat.qrCode`로 제한하여 QR 코드 외의 다른 바코드는 무시하도록 처리했습니다.
```dart
MobileScanner(
  controller: MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // 중복 인식 방지 (Cool-down)
    formats: [BarcodeFormat.qrCode], // QR 코드 포맷만 인식
  ),
  onDetect: (capture) { ... }
)
```

### 2. 음성 채팅 볼륨 동기화 이슈
*   **문제**: 인앱 음성 채팅 볼륨이 디바이스의 물리적 볼륨 버튼과 동기화되지 않거나, 미디어 볼륨 대신 통화 볼륨으로 잘못 잡히는 현상.
*   **해결**: `flutter_volume_controller`를 도입하여 하드웨어 볼륨 버튼 이벤트를 리스닝하고, `VoiceService`에서 PCM 오디오 재생 시 디바이스 볼륨을 반영하도록 소프트웨어적 스케일링을 구현했습니다.

### 3. 다크 모드(Dark Mode) UI 호환성
*   **문제**: 다크 모드 활성화 시 텍스트나 아이콘이 배경색과 겹쳐 보이지 않는 시인성 문제.
*   **해결**: 하드코딩된 색상 값을 `Theme.of(context)` 기반의 동적 색상으로 전면 교체하고, `LoginScreen` 및 `TutorialScreen`의 디자인을 테마에 맞춰 최적화했습니다.

### 4. 플레이어 마커 가시성 개선 (Map Clutter)
*   **문제**: 플레이어의 닉네임과 아이콘이 겹쳐 지도 시인성이 떨어지고 아군/적군 식별이 어려움.
*   **해결**: '가시성 모드(Visibility Mode)'를 도입하여 마커를 단순한 색상 점(Dot)으로 표현하고, 감옥 영역을 반투명 원형 오버레이로 시각화하여 직관성을 높였습니다.

---
*Last Updated: 2026-01-15*
