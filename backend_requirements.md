# 🚓 경도(경찰과 도둑) 백엔드 개발 요구사항 명세서

## 1. 개요
이 문서는 '경찰과 도둑' 플러터 앱을 위한 백엔드 API 및 소켓 이벤트 요구사항을 기술합니다.
핵심 기능은 **실시간 위치 공유**, **방 관리**, **게임 로직 처리**, **채팅**입니다.

---

## 2. 기술 스택 권장사항
- **Server**: Node.js (Socket.io) 또는 Go/Python (WebSocket) 권장 (실시간성 중요)
- **Voice Server**: **LiveKit**, **Mediasoup**, 또는 **Agora** (WebRTC 기반 SFU/MCU)
- **Database**: 
  - **Redis**: 실시간 위치 정보 및 세션 관리 (고속 처리)
  - **MongoDB/PostgreSQL**: 사용자 기록, 게임 결과, 로그 저장

---

## 3. 기능 명세

### 3.1 사용자 (User)
- **로그인/기기 인증**: 디바이스 ID 또는 닉네임 기반의 간편 인증
- **프로필 관리**: 닉네임 변경, 전적 조회

### 3.2 방 관리 (Room System)
REST API 또는 Socket Event로 구현

| 기능 | 설명 | 필요한 데이터 |
|---|---|---|
| **방 생성** | 호스트가 새로운 게임 방 생성 | 게임 설정(시간, 인원, 범위 등), 호스트 정보 |
| **방 입장** | 참여 코드로 방 입장 | 방 코드, 유저 정보 |
| **방 정보 조회** | 현재 대기방의 인원 및 상태 확인 | 방 코드 |
| **팀 설정** | 경찰/도둑 팀 배정 및 변경 | 유저 ID, 변경할 역할 |
| **준비(Ready)** | 게임 시작 전 준비 상태 토글 | 유저 ID, 상태(true/false) |

### 3.3 게임 플레이 (Real-time Game Logic)
**WebSocket/Socket.io 필수**

#### A. 위치 동기화 (Core)
- **위치 업데이트**: 클라이언트가 주기적(예: 1초)으로 내 위치 전송
- **위치 브로드캐스트**: 
  - **경찰**: 도둑의 위치를 간헐적으로 확인 (게임 설정에 따름) 또는 특정 아이템 사용 시 확인
  - **도둑**: 경찰의 위치를 (설정에 따라) 확인
  - **관전자**: 모든 플레이어 위치 실시간 확인

#### B. 게임 상태 관리
- **게임 시작**: 호스트가 시작 시 모든 클라이언트에 시작 신호 및 게임 종료 시간 전송
- **잡기(Arrest)**: 
  - 경찰이 도둑 근처(예: 3m 이내)에서 "잡기" 버튼 클릭
  - 서버에서 두 좌표 거리 검증 후 체포 판정
  - 해당 도둑은 "감옥" 상태로 변경 (이동 불가 또는 아웃)
- **영역 이탈**: 설정된 반경(중심점 기준)을 벗어난 유저 감지 및 경고/패널티 처리
- **게임 종료 판정**:
  - **경찰 승**: 제한 시간 내 모든 도둑 체포
  - **도둑 승**: 제한 시간 종료 시 도둑 생존

### 3.4 채팅 (Chat & Voice)
- **전체 채팅**: 방에 있는 모든 유저에게 텍스트 메시지 전송
- **팀 채팅**: 같은 팀(경찰/도둑)끼리만 보이는 텍스트 메시지
- **시스템 메시지**: "000님이 입장했습니다", "000님이 체포되었습니다" 등
- **음성 채팅 (무전기 - Walkie Talkie)**:
  - **Push-to-Talk (PTT)**: 버튼을 누르고 있는 동안만 음성 전송
  - **팀별 채널 분리**: 경찰팀과 도둑팀은 서로의 음성을 들을 수 없음
  - **상태 표시**: 누가 말하고 있는지 UI에 표시 (Speaking Indicator)
  - **기술 방식**: WebRTC (LiveKit, Agora 권장) 또는 SFU 서버 구축

### 3.5 기록 및 리플레이 (History & Replay)
- **게임 결과 저장**: 승패 팀, MVP, 플레이 타임 등 DB 저장
- **경로 저장 (Replay)**: 
  - 게임 중 모든 플레이어의 이동 경로(좌표 + 타임스탬프)를 시계열 데이터로 저장
  - 클라이언트에서 '다시보기' 시 해당 데이터 제공

---

## 4. API 엔드포인트 예시 (REST)

### Auth
- `POST /api/auth/login`: 로그인 및 토큰 발급
- `PATCH /api/user/profile`: 닉네임 수정

### Room
- `POST /api/rooms`: 방 생성 (return: roomCode)
- `GET /api/rooms/{roomCode}`: 방 정보 조회
- `POST /api/rooms/join`: 방 입장

### Records
- `GET /api/records/my`: 내 전적 조회
- `GET /api/records/history/{gameId}`: 특정 게임 상세 기록 및 리플레이 데이터 조회

---

## 5. 소켓 이벤트 예시 (Socket.io)

### Client -> Server
- `join_room`: 방 입장 요청
- `update_location`: 내 위치 전송 (lat, lng)
- `attempt_arrest`: 체포 시도 (targetId)
- `send_message`: 채팅 메시지 전송

### Server -> Client
- `room_state`: 방 멤버 변경 시 전체 목록 갱신
- `game_start`: 게임 시작 알림
- `update_positions`: 다른 플레이어들의 위치 배열
- `player_arrested`: 누군가 체포되었을 때 알림
- `game_over`: 게임 종료 및 결과 전송

---

## 6. 데이터 구조 설계 (Data Structure)

### 6.1 Database Schema (MongoDB Example)

#### Users Collection
```json
{
  "_id": "ObjectId",
  "deviceId": "String (Unique)",
  "nickname": "String",
  "createdAt": "Date",
  "stats": {
    "totalGames": "Number",
    "policeWins": "Number",
    "thiefWins": "Number",
    "mvpCount": "Number"
  }
}
```

#### GameHistory Collection
```json
{
  "_id": "ObjectId",
  "roomId": "String",
  "startTime": "Date",
  "endTime": "Date",
  "mode": "String (Classic, etc)",
  "winnerTeam": "String (POLICE, THIEF)",
  "settings": {
    "timeLimit": "Number",
    "areaRadius": "Number"
  },
  "players": [
    {
      "userId": "ObjectId",
      "nickname": "String",
      "team": "String",
      "isMvp": "Boolean",
      "result": "String (WIN, LOSE, ARRESTED)"
    }
  ]
}
```

#### Replays Collection
```json
{
  "_id": "ObjectId",
  "gameId": "ObjectId (Ref: GameHistory)",
  "frames": [
    {
      "timestamp": "Number (Offset ms)",
      "events": [
        {
          "type": "String (MOVE, ARREST, CHAT, VOICE_ON)",
          "userId": "ObjectId",
          "data": {
            "lat": "Number",
            "lng": "Number",
            "targetId": "ObjectId"
          }
        }
      ]
    }
  ]
}
```

### 6.2 Redis Data Structure (In-Memory)

실시간 게임 상태 관리를 위해 사용합니다.

- **Room Key**: `room:{roomId}` (Hash)
  - `state`: WAITING, PLAYING, ENDED
  - `hostId`: {userId}
  - `settings`: {JSON String}
  
- **Player Key**: `room:{roomId}:players` (Hash)
  - `{userId}`: {
      "team": "POLICE",
      "status": "ALIVE", // or ARRESTED
      "lat": 37.5...,
      "lng": 127.0...,
      "lastUpdate": 1700000000
    }

---

## 7. Socket Message Payload 상세

### Location Update (Client -> Server)
```json
{
  "event": "update_location",
  "data": {
    "lat": 37.5665,
    "lng": 126.9780,
    "speed": 4.5, // m/s (부정행위 감지용)
    "heading": 90.0
  }
}
```

### Game State Broadcast (Server -> Client)
```json
{
  "event": "update_positions",
  "data": {
    "players": [
      {
        "id": "user123",
        "team": "THIEF",
        "lat": 37.5665,
        "lng": 126.9780,
        "isTalking": true // 음성 채팅 중 여부
      },
      // ...
    ]
  }
}
```
