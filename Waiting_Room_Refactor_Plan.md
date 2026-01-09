# Waiting Room Firebase Direct Connection Implementation Plan

## Goal Description
Refactor the Waiting Room logic to remove HTTP polling and establish a direct real-time connection to Firebase Realtime Database (RTDB) for fetching and updating room status. This aligns with the user's request to minimize backend dependency for real-time updates.

## User Review Required
> [!IMPORTANT]
> This change replaces HTTP polling with Firebase RTDB listeners. Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly configured as verified in previous steps.

## Proposed Changes

### Service Layer Refactoring
#### [MODIFY] [lib/services/room_service.dart](file:///c:/HWS/Flutter/gyeong_do/lib/services/room_service.dart)
- **Rename**: `HttpRoomService` -> `FirebaseRoomService` (or keep name but change impl).
- **Remove**: `_startPolling`, `_stopPolling`, `_fetchRoomStatus`, `_pollTimers` logic.
- **Implement**: `getRoomStream(roomId)` using `FirebaseDatabase.instance.ref('rooms/$roomId').onValue`.
- **Implement**: `updateMyStatus` (team selection, ready toggle) using direct Firebase writes if security rules allow, OR keep HTTP calls for *actions* but use Firebase for *listening*.
    - *Security Rules Analysis*:
        - `rooms/$roomId`: `.write: false` (Clients cannot write directly to room root).
        - `rooms/$roomId/participants`: `.read: auth != null`.
        - There is NO write permission explicit for clients on `rooms/$roomId` or `participants` in the provided `security_rules.json`.
        - **Conclusion**: Actions (`join`, `ready`, `changeTeam`, `startGame`) MUST still use HTTP endpoints because clients don't have write access to the room state in DB.
        - **Change**: Only `getRoomStream` (read) will be direct Firebase. Actions remain HTTP.

### UI Layer Updates
#### [MODIFY] [lib/screens/waiting_room_screen.dart](file:///c:/HWS/Flutter/gyeong_do/lib/screens/waiting_room_screen.dart)
- No major changes expected if `RoomService.getRoomStream` contract remains the same, but verified to ensure it handles the Firebase-emitted stream correctly.

### Dependency Injection
#### [MODIFY] [lib/main.dart](file:///c:/HWS/Flutter/gyeong_do/lib/main.dart)
- Update `NetworkService` provider if separation exists, or ensure `FirebaseRoomService` is provided.

## Verification Plan

### Manual Verification
1.  **Enter Waiting Room**: Create or join a room.
2.  **Real-time Updates**:
    - Have another device/client join the room.
    - Verify the player list updates immediately without polling delay.
    - Toggle "Ready" status and verify update.
    - Change Team and verify update.
3.  **Start Game**: Host starts game, verify all clients transition.
