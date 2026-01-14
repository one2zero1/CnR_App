class AppStrings {
  // Button Labels
  static const String confirm = '확인';
  static const String cancel = '취소';
  static const String close = '닫기';
  static const String copy = '복사';
  static const String start = '시작';
  static const String ready = '준비';
  static const String unready = '준비 해제';
  static const String gameStart = '게임 시작';
  static const String leaveRoom = '방 나가기';

  // Waiting Room
  static const String waitingRoomTitle = '대기실';
  static const String roomCode = '입장 코드';
  static const String pinCodeLabel = 'PIN CODE';
  static const String pinCopied = 'PIN 코드가 복사되었습니다.';
  static const String codeCopied = '코드가 복사되었습니다!';
  static const String copyCodeTooltip = '코드 복사';
  static const String viewQrTooltip = 'QR 코드 보기';
  static const String qrCodeTitle = '방 입장 QR 코드';
  static const String playerCountFormat = '현재 인원 %d/8명';
  static const String meTag = '나';
  static const String waitingStatus = '대기중...';
  static const String readyStatus = '준비완료';
  static const String roleUnknown = '❓ 미정';
  static const String rolePolice = '👮 경찰';
  static const String roleThief = '🏃 도둑';
  static const String roleNone = '팀 선택 필요';
  static const String waitingForPlayers = '플레이어 대기 중...';
  static const String chatTitle = '대기실 채팅';
  static const String joinChat = '채팅에 참여하세요';

  // Room Admin
  static const String manageUserFormat = '%s 관리';
  static const String forceChangeRole = '역할 강제 변경';
  static const String kickUser = '강제 퇴장';
  static const String userKicked = '사용자를 강제 퇴장시켰습니다.';
  static const String selectRole = '역할 선택';

  static const String alertRoomLink = '참여 링크 QR코드';
  static const String alertKickTitle = '강퇴하기';
  static const String alertKickMessage = '이 사용자를 정말 강퇴하시겠습니까?';
  static const String alertChangeRoleTitle = '팀 강제 변경';
  static const String alertChangeRoleMessage = '이 사용자의 팀을 변경하시겠습니까?';

  // Settings
  static const String settingsTitle = '설정';
  static const String settingsScreen = '화면 설정';
  static const String settingsSystem = '시스템 설정 따름';
  static const String settingsLight = '라이트 모드';
  static const String settingsDark = '다크 모드';
  static const String settingsNotifications = '알림';
  static const String notifLocationTitle = '위치 공개 알림';
  static const String notifLocationSub = '도둑 위치가 공개될 때 알림';
  static const String notifCaptureTitle = '포획 알림';
  static const String notifCaptureSub = '도둑이 잡혔을 때 알림';
  static const String notifChatTitle = '채팅 알림';
  static const String notifChatSub = '새로운 채팅 메시지 알림';
  static const String settingsMap = '지도';
  static const String mapStyle = '지도 스타일';
  static const String mapStyleNormal = '일반';
  static const String mapStyleSatellite = '위성';
  static const String gpsAccuracy = 'GPS 정확도';
  static const String gpsHigh = '높음 (정확도 우선)';
  static const String gpsLow = '낮음 (배터리 절약)';
  static const String gpsNormal = '보통';
  static const String battery = '배터리';
  static const String accuracy = '정확도';
  static const String settingsBattery = '배터리'; // Section
  static const String powerSave = '절전 모드';
  static const String powerSaveSub = 'GPS 업데이트 주기를 줄여 배터리 절약';
  static const String settingsAccount = '계정';
  static const String changeNickname = '닉네임 변경';
  static const String logout = '로그아웃';
  static const String settingsAppInfo = '앱 정보';
  static const String version = '버전';
  static const String tutorialRestart = '튜토리얼 다시 보기';
  static const String terms = '이용약관';
  static const String privacy = '개인정보 처리방침';

  // Move To Jail
  static const String moveToJailTitle = '감옥으로 이동';
  static const String cantGoBack = '감옥으로 이동해야 합니다 뒤로 갈 수 없습니다.';
  static const String giveUp = '포기';
  static const String arrestedTitle = '🚨 체포되었습니다!';
  static const String arrestedContent =
      '스스로 감옥으로 이동하세요.\n감옥에 도착해야 이후 플레이가 가능합니다.';
  static const String distanceRemaining = '남은 거리: %dm';
  static const String enterJail = '감옥 입장하기';
  static const String moveToJailGuide = '감옥으로 이동하세요';

  // Dialogs
  static const String leaveRoomTitle = '방 나가기';
  static const String leaveRoomContent = '정말 방을 나가시겠습니까?';
  static const String changeNicknameTitle = '닉네임 변경';
  static const String newNicknameHint = '새 닉네임 입력';
  static const String nicknameChanged = '닉네임이 변경되었습니다';
  static const String change = '변경';
  static const String logoutTitle = '로그아웃';
  static const String logoutContent = '정말 로그아웃 하시겠습니까?';
  static const String giveUpTitle = '게임 포기';
  static const String giveUpContent = '정말 게임을 포기하시겠습니까?\n포기하면 결과 화면으로 이동합니다.';
  static const String giveUpConfirm = '포기하기';

  // Errors
  static const String errorKicked = '방에서 강퇴당했습니다.';
  static const String errorRoomDeleted = '방이 삭제되었습니다.';
  static const String errorGeneric = '오류 발생';
  static const String changeTeamFailed = '팀 변경 실패: ';
  static const String startGameFailed = '게임 시작 실패: ';
  static const String leaveRoomFailed = '방 나가기 실패: ';
  static const String kickUserFailed = '강퇴 실패: ';
  static const String changeRoleFailed = '역할 변경 실패: ';

  // Tooltips
  static const String tooltipAdmin = '방장';

  // Thief Catching
  static const String caughtQrTitle = '체포 확인 QR';
  static const String caughtQrDesc = '경찰에게 이 코드를 보여주세요';
  static const String arrestButton = '검거하기';
  static const String scanQrTitle = '도둑 QR 스캔';
  static const String scanQrGuide = '도둑의 QR 코드를 사각형 안에 비추세요';
  static const String arrestSuccess = '검거 성공!';
  static const String arrestFail = '검거 실패. 다시 시도해주세요.';
  static const String checkingResult = '확인 중...';
}
