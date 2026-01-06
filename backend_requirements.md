# 🚓 Cops and Robbers (현대판 경찰과 도둑) 백엔드 요구사항 명세서

## 1. 개요 및 목표
이 문서는 'Cops and Robbers (현대판 경찰과 도둑)' 플러터 앱을 위한 백엔드 인프라 및 데이터 구조를 기술합니다.
**핵심 목표**는 **실시간 위치 공유 및 소셜 액티비티 관리를 위한 안정적인 서버 인프라 구축**입니다.

---

## 2. 기술 스택 (Firebase 기반)
- **Language**: Dart (Flutter Backendless)
- **Auth**: Firebase Authentication (로그인/세션 관리)
- **Main DB**: Cloud Firestore (영구 데이터 저장: 회원 정보, 전적, 게임 기록)
- **Realtime Engine**: Firebase Realtime Database (초단위 실시간 데이터: 좌표, 방 상태)
- **Notification**: FCM (Firebase Cloud Messaging) - 푸시 알림

---

## 3. 역할 정의 (Roles)

| 역할 | 설명 | 핵심 메커니즘 |
|---|---|---|
| **경찰 (Police)** | 도둑을 추격하여 검거하는 역할 | • 실시간 GPS로 도둑 위치 파악 및 포위망 구축<br>• 감옥 주변 감시로 구출 차단 |
| **도둑 (Thief)** | 경찰을 피해 생존하는 역할 | • 추격을 따돌리고 은신<br>• 감옥에 갇힌 동료 구출<br>• 제한 시간까지 생존 |

---

## 4. 상세 기능 명세 및 구현 항목

### 4.1 회원 및 전적 관리 (Member & Stats)
- **Auth**: Firebase Auth 기반 계정 시스템
- **전적 관리**:
  - 경찰/도둑 승률 분리 집계
  - 공통: 총 플레이 횟수, 매너 점수
  - 시즌제 랭킹 (승률 기반 리더보드)
  - *게임 종료 시 '정상 종료'된 경우에만 승률 반영*

### 4.2 세션 기반 게임 관리 (Session Management)
- **방 생성**: 6자리 PIN 코드 발급, 종료 시각(Expiration Time) 계산
- **팀 배정**: 사용자 수동 선택 (게임 시작 후 변경 불가)
- **게임 시작**: 호스트 권한, 인원 수 검증
- **상태 관리**:
  - **세션 유지**: 재입장(Rejoin) 처리 지원
  - **세션 만료**: 타이머 종료 시 실시간 노드 삭제 및 Firestore로 결과 이관
  - **강제 종료**: 호스트 권한으로 게임 중단 가능

### 4.3 실시간 엔진 (Real-time Engine)
- **Realtime Database** 활용
- 초단위 GPS 좌표 데이터 중계
- 팀별 위치 브로드캐스팅 및 가시성(Visibility) 제어 로직 적용

### 4.4 알림 시스템 (Notification)
- **FCM 기반**: 게임 시작, 팀원 검거/구출 시 실시간 푸시
- **경고**: 활동 반경(Activity Boundary) 이탈 시 알림
- **네트워크 상태**: 연결 끊김 감지 및 알림 아이콘 표시

### 4.5 보안 및 치팅 방지
- **Speed Detection**: 비정상적인 이동 속도 감지 (순간이동 방지)
- **Server Validation**: 검거/구출 시 서버 측 거리(Distance) 검증

### 4.6 결과 분석
- 개인별 이동 거리 및 활동량(Kcal) 분석
- 최종 결과 레포트 및 SNS 공유 이미지 제공
- 매너 점수 시스템 (신고/칭찬)

---

## 5. 데이터 모델 설계 (Data Model)

### 5.1 Cloud Firestore (Persistent Data)
영구적으로 보관해야 할 데이터입니다.

#### `users` Collection
- `uid`: String
- `nickname`: String
- `profile_img`: String
- `manner_point`: Number
- `police_stats`: { `police_wins`, `police_games_played` }
- `thief_stats`: { `thief_wins`, `thief_games_played` }
- `report_history`: { `reported_count`, `praised_count` }

#### `game_history` Collection
- `game_id`: String
- `date`: Timestamp
- `duration`: Number
- `winner_team`: String
- `participant_uids`: List<String>
- `end_type`: String (normal, force_ended)
- `ended_by`: String (uid)

### 5.2 Realtime Database (Live Data)
게임 진행 중에만 유지되는 휘발성 데이터입니다.

#### `rooms/{room_id}` Node
- **session_info**:
  - `status`: waiting | playing | cleaning | force_ended
  - `host_id`: String
  - `pin_code`: String
  - `expires_at`: Timestamp
  - `force_end`: { `ended_by`, `ended_at`, `reason` }
  
- **participants/{user_id}**:
  - `nickname`: String
  - `team`: police | thief | unassigned
  - `ready`: Boolean

- **game_system_rules**:
  - `game_duration_sec`: Int
  - `activity_boundary`: { `center_lat`, `center_lng`, `radius_meter`, `alert_on_exit` }
  - `prison_location`: { `lat`, `lng`, `radius_meter` }
  - `location_policy`:
    - `reveal_mode`: always | interval
    - `police_can_see_thieves`: Boolean
    - `thieves_can_see_police`: Boolean
  - `capture_rules`:
    - `trigger_distance_meter`: 5m
    - `capture_cooldown_sec`: 3s
  - `release_rules`:
    - `trigger_distance_meter`: 10m
    - `release_duration_sec`: 5s (Hold)
    - `interrupt_distance_meter`: 15m
  - `victory_conditions`:
    - `police_win`: all_thieves_captured
    - `thief_win`: survive_until_timeout

- **convenience_features**:
  - `voice_channel_id`: String
  - `chat_enabled`: Boolean

#### `live_status/{room_id}/{user_id}` Node
- `pos`: { `lat`, `lng` }
- `role`: police | thief
- `state`: { `is_captured`, `captured_at`, `is_released` }
- `connection_state`:
  - `status`: online | disconnected | abandoned
  - `last_ping`: Timestamp
  - `disconnect_at`: Timestamp (3분 유예)

#### `chat/{room_id}` Node
- List of { `uid`, `message`, `timestamp` }

---

## 6. 게임 로직 및 흐름 (Game Flow Logic)

### 6.1 승리 조건
- **경찰 승리**: 제한 시간 내 모든 도둑 검거 완료
- **도둑 승리**: 제한 시간 종료 시 도둑이 최소 1명 이상 생존 (또는 감옥 밖 활동)

### 6.2 검거 (Capture) 메커니즘
- **조건**: 경찰이 도둑 **5m 이내** 접근
- **액션**: [검거하기] 버튼 클릭 (서버 거리 검증 필수)
- **쿨다운**: 3초 (연속 검거 방지)
- **처리**: 도둑 상태 `is_captured = true`, 감옥으로 이동(UI 처리)

### 6.3 구출 (Release) 메커니즘
- **조건**: 생존 도둑이 감옥(Rescue Zone) **10m 이내** 접근
- **액션**: [구출하기] 버튼 **5초간 터치 유지 (Hold)**
- **방해 (Interruption)**: 경찰이 구출 중인 도둑의 **15m 이내** 접근 시 구출 자동 중단

### 6.4 네트워크 연결 끊김 처리 (Disconnection Handling)
- **Online**: 정상 (10초 주기 Ping)
- **Disconnected**: 30초 이상 Ping 없을 시 상태 변경. **3분(180초)의 재접속 유예 시간(Grace Period)** 제공.
- **Abandoned**: 3분 내 재접속 실패 시 '탈주' 처리 (자동 아웃, 매너 점수 -10 차감)
- **Rejoin**: 앱 재실행 시 로컬 저장소 확인 후 재접속 다이얼로그 표시

### 6.5 경계 이탈 (Boundary Violation)
- 실시간 GPS 좌표가 `activity_boundary.radius_meter`를 벗어나면 경고 알림 전송

---

## 7. API & 통신 구조 요약
- **Auth**: Firebase SDK 직접 사용
- **Game Data Sync**: `FirebaseDatabase.instance.ref('rooms/$roomId').onValue` 스트림 구독
- **Location Sync**: `Geolocator` 스트림 -> `live_status` 노드 업데이트 (쓰기)
- **Chat**: `chat` 노드에 push (쓰기) 및 `onChildAdded` 리스너 (읽기)
