# 프론트엔드 기술 스택 및 개발 환경 정의서

## 1. 개발 환경 (Development Environment)
본 프로젝트는 **Flutter** 프레임워크를 기반으로 개발되었습니다.

| 항목 | 상세 내용 | 비고 |
| :--- | :--- | :--- |
| **OS** | Windows | 개발 운영체제 |
| **Language** | Dart | Flutter 언어 |
| **SDK Constraint** | `^3.10.4` | `pubspec.yaml` 기준 |

<br>

## 2. 기술 스택 (Technology Stack)

### 2.1 Core Framework & State Management
- **Flutter**: 크로스 플랫폼 UI 프레임워크
- **Provider** (`^6.1.2`): 전역 및 로컬 상태 관리 솔루션
- **Flutter Dotenv** (`^5.2.1`): `.env` 파일을 통한 환경 변수 관리 (API 키, URL 등 보안 처리)

### 2.2 Infrastructure & Backend (Firebase)
- **Firebase Core** (`^3.10.1`): Firebase 초기화 및 연동
- **Firebase Auth** (`^5.3.4`): 사용자 인증 처리
- **Firebase Database** (`^11.3.1`): Realtime Database를 이용한 실시간 데이터 동기화

### 2.3 Maps & Location (지도 및 위치 기반 서비스)
- **Flutter Map** (`^7.0.2`): 오픈소스 기반 지도 렌더링 엔진
- **Latlong2** (`^0.9.1`): 위도/경도 좌표 계산 및 처리 유틸리티
- **Geolocator** (`^13.0.2`): 디바이스의 현재 GPS 위치 정보 수집

### 2.4 Voice & Audio (음성 통신)
- **Sound Stream** (`^0.4.1`): 마이크 입력 및 오디오 출력 스트림 제어
- **Audio Session** (`^0.1.18`): iOS/Android 오디오 세션 설정 및 관리
- **Permission Handler** (`^11.3.0`): 마이크, 위치 등 런타임 권한 요청 및 상태 확인

### 2.5 QR System (QR 코드)
- **QR Flutter** (`^4.1.0`): QR 코드 이미지 생성 및 렌더링
- **Mobile Scanner** (`^6.0.2`): 카메라를 이용한 QR 코드 스캔 기능

### 2.6 Local Storage & Utilities
- **Shared Preferences** (`^2.3.4`): 디바이스 로컬 키-값 저장소 (설정, 간단한 데이터 저장)
- **Intl** (`^0.20.1`): 날짜/시간 포맷팅 및 다국어 지원 준비
- **Uuid** (`^4.5.1`): 고유 식별자(UUID) 생성

<br>

## 3. 주요 디렉토리 구조 (Project Structure)
- `lib/config/`: 환경 설정 및 상수 문자열
- `lib/services/`: 비즈니스 로직 및 외부 서비스 연동 (Auth, Room, Game, Voice 등)
- `lib/theme/`: 앱 디자인 시스템 (Colors, Sizes)
- `lib/screens/`: UI 화면 구성

---
*Last Updated: 2026-01-13*
