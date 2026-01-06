# 🚓 경도 (Gyeong-Do) - 경찰과 도둑

**실시간 위치 기반 리얼 술래잡기 모바일 게임**

어린 시절 즐겨하던 '경찰과 도둑' 게임을 스마트폰과 GPS를 활용해 현실 세계에서 더욱 짜릿하게 즐겨보세요!

## 📱 프로젝트 소개

'경도'는 사용자들이 직접 경찰과 도둑이 되어, 설정된 현실 공간(공원, 학교 등)에서 추격전을 벌이는 게임입니다.
실시간으로 위치를 공유하고, 채팅과 음성 무전기를 통해 팀원과 전략을 짜며 플레이할 수 있습니다.

## ✨ 주요 기능

*   **실시간 위치 추적**: `flutter_map`과 `geolocator`를 사용하여 내 위치와 팀원의 위치를 지도에 실시간으로 표시합니다.
*   **게임 모드**:
    *   **경찰**: 도둑을 찾아 지정된 거리 내에서 체포합니다.
    *   **도둑**: 제한 시간 동안 경찰을 피해 생존해야 합니다.
*   **영역 설정**: 호스트가 지도에서 게임 플레이 영역(원형 반경)을 설정합니다. 영역 이탈 시 경고가 발생합니다.
*   **팀 커뮤니케이션**:
    *   실시간 텍스트 채팅
    *   **음성 무전기 (Walkie-Talkie)**: PTT(Push-To-Talk) 방식으로 팀원과 긴밀하게 소통합니다.
*   **리플레이**: 게임 종료 후 플레이어들의 이동 경로를 다시 볼 수 있습니다.

## 🛠 기술 스택

### Frontend
*   **Framework**: [Flutter](https://flutter.dev/)
*   **Map**: `flutter_map` (OpenStreetMap 기반), `latlong2`
*   **Location**: `geolocator`
*   **State Management**: `provider` (예정), `setState`
*   **Language**: Dart

### Backend (Planned)
자세한 내용은 [backend_requirements.md](backend_requirements.md) 문서를 참고하세요.
*   **Server**: Socket.io / WebSocket
*   **Voice**: WebRTC (LiveKit / Agora)
*   **DB**: MongoDB, Redis

## 🚀 시작하기 (Getting Started)

### 사전 요구사항
*   Flutter SDK 설치 완료
*   Android Studio 또는 VS Code
*   Android Emulator 또는 실물 기기 (GPS 테스트 권장)

### 설치 및 실행

1. **레포지토리 클론**
   ```bash
   git clone https://github.com/your-repo/gyeong-do.git
   cd gyeong-do
   ```

2. **패키지 설치**
   ```bash
   flutter pub get
   ```

3. **환경 변수 설정**
   * 프로젝트 루트에 `.env` 파일을 생성하고 필요한 설정을 추가하세요. (현재는 지도 API 키 불필요)
   ```env
   # SOCKET_SERVER_URL=http://your-server-ip:3000
   ```

4. **앱 실행**
   ```bash
   flutter run
   ```

## 📂 프로젝트 구조

```
lib/
├── config/          # 환경 변수 및 설정
├── screens/         # 화면 UI (GamePlay, Settings 등)
├── theme/           # 앱 테마 (색상, 폰트)
├── widgets/         # 재사용 가능한 위젯 (FlutterMapWidget 등)
└── main.dart        # 앱 진입점
```

## 📝 라이선스

This project is licensed under the MIT License.
