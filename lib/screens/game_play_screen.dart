import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/flutter_map_widget.dart';
import 'chat_screen.dart';
import '../models/chat_model.dart'; // Import Chat Models
import '../services/chat_service.dart'; // Import Chat Service
import '../utils/toast_util.dart';
import '../utils/loading_util.dart'; // Import Loading Util
import '../config/app_strings.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/game_types.dart';
import '../models/room_model.dart'; // For GameSettings
import '../models/live_status_model.dart';
import 'move_to_jail_screen.dart';
import '../services/game_play_service.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import '../services/room_service.dart';
import 'game_result_screen.dart';
import 'home_screen.dart';

class GamePlayScreen extends StatefulWidget {
  final TeamRole role;
  final String gameName;
  final String roomId;
  final GameSystemRules settings;
  final bool isHost;

  const GamePlayScreen({
    super.key,
    required this.role,
    required this.gameName,
    required this.roomId,
    required this.settings,
    required this.isHost,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  int _remainingSeconds = 600;
  int _nextRevealSeconds = 0; // 초기화는 initState에서
  bool _showingLocationAlert = false;
  bool _isTalking = false;

  // 알림 로직을 위한 상태 변수
  Set<String> _prevCapturedUids = {};
  bool _isFirstStatusUpdate = true;

  // 채팅 관련
  final TextEditingController _chatController = TextEditingController();
  bool _isComposing = false;

  // 위치 관련
  late MapController _mapController;
  LatLng _currentPosition = const LatLng(37.5665, 126.9780);
  StreamSubscription<Position>? _positionStream;
  Stream<List<LiveStatusModel>>? _statusStream;
  StreamSubscription<RoomModel>? _roomSubscription;
  bool _isNavigating = false;
  RoomModel? _cachedRoom;
  int _capturedThieves = 0;
  int _totalThieves = 0;
  StreamSubscription<List<LiveStatusModel>>? _statusSubscription;
  List<LiveStatusModel> _latestStatuses = []; // Cache for snapshots
  Map<String, LatLng> _visibleOpponentLocations = {}; // Snapshot data
  bool _hasInitialSnapshot = false;

  String? _myId;

  // ... (Voice Chat state remains same) ...
  String? _speakingNickname;
  Timer? _speakingTimer;
  late final VoiceService _voiceService;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _myId = authService.currentUser?.uid;
    final gamePlayService = context.read<GamePlayService>();
    _voiceService = context.read<VoiceService>();

    // Start Voice Listening
    _voiceService.init().then((_) {
      _voiceService.startListening(widget.roomId, widget.role);
    });

    // Listen to who is talking
    _voiceService.whoIsTalkingStream.listen((nickname) {
      if (mounted) {
        setState(() {
          _speakingNickname = nickname;
        });
        _speakingTimer?.cancel();
        _speakingTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _speakingNickname = null);
          }
        });
      }
    });

    // Broadcast stream to allow multiple listeners (Map + Logic)
    _statusStream = gamePlayService
        .getLiveStatusesStream(widget.roomId)
        .asBroadcastStream();

    // Listen for Captured Count Updates & My Status & Cache
    _statusSubscription = _statusStream!.listen((statuses) {
      if (!mounted) return;

      _latestStatuses = statuses;

      // Initial Snapshot Logic
      final interval = widget.settings.locationPolicy.revealIntervalSec ?? 0;
      if (interval > 0 && !_hasInitialSnapshot && statuses.isNotEmpty) {
        _updateOpponentSnapshots();
        _hasInitialSnapshot = true;
      }

      // Calculate captured thieves for UI count
      final currentCapturedUids = statuses
          .where(
            (s) => s.role == TeamRole.thief && s.state == PlayerState.captured,
          )
          .map((s) => s.uid)
          .toSet();

      final capturedCount = currentCapturedUids.length;

      if (_capturedThieves != capturedCount) {
        setState(() {
          _capturedThieves = capturedCount;
        });
      }

      // --- Notification Logic (Capture & Release) ---
      if (_isFirstStatusUpdate) {
        // 첫 진입 시 동기화만 하고 알림 스킵
        _prevCapturedUids = currentCapturedUids;
        _isFirstStatusUpdate = false;
      } else {
        // 1. 잡힌 도둑 감지 (이전엔 없었는데 새로 생긴 ID)
        final newlyCaptured = currentCapturedUids.difference(_prevCapturedUids);
        if (newlyCaptured.isNotEmpty) {
          final participants = _cachedRoom?.participants ?? {};
          for (final uid in newlyCaptured) {
            final nickname = participants[uid]?.nickname ?? 'Unknown';
            ToastUtil.show(
              context,
              '$nickname님이 잡혔습니다!',
              isError: true, // 강조를 위해 에러 스타일(붉은색/경고색) 사용 가능
            );
          }
        }

        // 2. 풀려난 도둑 감지 (이전엔 있었는데 지금은 없는 ID)
        // 누군가 풀려났다면 "모든 도둑이 풀려났습니다" 메시지 (일괄 석방 가정)
        // 만약 개별 석방이라도, 풀려난 사람이 있으면 알림
        final newlyReleased = _prevCapturedUids.difference(currentCapturedUids);
        if (newlyReleased.isNotEmpty) {
          ToastUtil.show(
            context,
            '모든 도둑이 풀려났습니다!', // 요구사항: "모든 도둑이 풀려났기 때문에, 모든 도둑이 풀려났다고 하기"
            isError: false,
          );
        }

        // 상태 업데이트
        _prevCapturedUids = currentCapturedUids;
      }
      // ---------------------------------------------

      // Check My Status (Auto Navigate to Jail if Captured)
      if (_myId != null && widget.role == TeamRole.thief) {
        try {
          final myStatus = statuses.firstWhere((s) => s.uid == _myId);

          if (myStatus.state == PlayerState.captured) {
            _statusSubscription?.cancel();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MoveToJailScreen(
                    jailPosition: LatLng(
                      widget.settings.prisonLocation.lat,
                      widget.settings.prisonLocation.lng,
                    ),
                    roomId: widget.roomId,
                    role: widget.role,
                    settings: widget.settings,
                    isHost: widget.isHost,
                  ),
                ),
              );
            }
          }
        } catch (_) {
          // Me not in list yet
        }
      }
    });

    // Initial Cache & Total Count
    _cachedRoom = context.read<RoomService>().getRoom(widget.roomId);
    if (_cachedRoom != null) {
      _totalThieves = _cachedRoom!.participants.values
          .where((p) => p.team == TeamRole.thief.name)
          .length;
    }

    _startRoomListener();
    _remainingSeconds = widget.settings.gameDurationSec; // Init time limit

    // Init Interval Timer
    final interval = widget.settings.locationPolicy.revealIntervalSec ?? 0;
    _nextRevealSeconds = interval > 0 ? interval : 0;

    _startTimer();
    _startLocationUpdates();
  }

  void _startRoomListener() {
    final roomService = context.read<RoomService>();
    _roomSubscription = roomService.getRoomStream(widget.roomId).listen((room) {
      if (mounted) {
        final total = room.participants.values
            .where((p) => p.team == TeamRole.thief.name)
            .length;

        setState(() {
          _cachedRoom = room;
          _totalThieves = total;
        });
      }

      if (_isNavigating) return;

      debugPrint('DEBUG: Room status update -> ${room.sessionInfo.status}');

      if (room.sessionInfo.status == 'force_ended' ||
          room.sessionInfo.status == 'ended' ||
          room.sessionInfo.status == 'cleaning' ||
          room.sessionInfo.status == 'waiting') {
        debugPrint('DEBUG: Detected game end. Navigating away...');
        _isNavigating = true;

        // Disconnect voice before leaving
        debugPrint('DEBUG: Stopping voice service...');
        _voiceService.stopListening();
        debugPrint('DEBUG: Voice service stopped. Pushing Navigation...');

        // Logic to determine winner (Heuristic)
        String? winner;
        if (room.sessionInfo.status == 'cleaning') {
          final isTimeOver = DateTime.now().isAfter(room.sessionInfo.expiresAt);
          winner = isTimeOver ? 'Thief' : 'Police';
        }

        if (mounted) {
          // 다이얼로그나 오버레이 등 모든 라우트를 정리하고 결과 화면으로 이동
          // 홈 하 화면(root)만 남기고 다 제거 후 결과 화면 push
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => GameResultScreen(
                gameName: widget.gameName,
                isHostEnded: room.sessionInfo.status == 'force_ended',
                winnerTeam: winner,
                roomId: widget.roomId,
              ),
            ),
            (route) => route.isFirst,
          );
        }
      }
    });
  }

  void _showEndGameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stop_circle_outlined,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '게임 종료 설정',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '게임을 어떻게 종료하시겠습니까?\n모든 플레이어에게 영향이 갑니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext); // Close menu dialog

                      // Show Loading
                      LoadingUtil.show(context, message: '게임을 다시 시작하는 중...');

                      // Call restart API
                      try {
                        if (!mounted) return;
                        await context.read<RoomService>().resetGame(
                          widget.roomId,
                          _myId!,
                        );
                        // Listener will handle navigation
                      } catch (e) {
                        // Hide loading on error
                        if (mounted) LoadingUtil.hide(context);
                        if (!mounted) return;
                        ToastUtil.show(context, '다시 시작 실패: $e', isError: true);
                      }
                      // Note: On success, listener handles navigation, but we might want to hide loading?
                      // Actually, if listener navigates away, hiding loading might be redundant but safe.
                      // However, resetGame causes room status change -> listener -> navigation.
                      // The loading dialog is part of the current context. Navigating away destroys it.
                      // So we strictly only need to hide it on error.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '다시 시작',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext); // Close menu dialog

                      // Show Loading
                      LoadingUtil.show(context, message: '게임을 종료하는 중...');

                      // Call end API
                      try {
                        if (!mounted) return;
                        await context.read<RoomService>().endGame(
                          widget.roomId,
                          _myId!,
                        );
                        // Listener will handle navigation
                      } catch (e) {
                        // Hide loading on error
                        if (mounted) LoadingUtil.hide(context);
                        if (!mounted) return;
                        ToastUtil.show(context, '게임 종료 실패: $e', isError: true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '완전 종료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('취소'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('DEBUG: GamePlayScreen dispose called');
    _voiceService.stopListening();
    _roomSubscription?.cancel();
    _statusSubscription?.cancel();
    _speakingTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          _updateServerLocation(_currentPosition);
        }
      } catch (e) {
        debugPrint('초기 위치 가져오기 실패: $e');
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            if (mounted) {
              final newPos = LatLng(position.latitude, position.longitude);
              setState(() => _currentPosition = newPos);
              _updateServerLocation(newPos);
              _checkBoundary(newPos);
            }
          });
    }
  }

  void _updateServerLocation(LatLng pos) {
    if (_myId == null) return;
    context.read<GamePlayService>().updateMyLocation(
      widget.roomId,
      _myId!,
      pos,
    );
  }

  void _checkBoundary(LatLng pos) {
    if (_myId == null) return;

    // Client-side boundary check
    final center = LatLng(
      widget.settings.activityBoundary.centerLat,
      widget.settings.activityBoundary.centerLng,
    );
    final int radius = widget.settings.activityBoundary.radiusMeter;

    const distance = Distance();
    final double currentDistance = distance.as(LengthUnit.Meter, pos, center);

    // 경계 이탈 체크
    if (currentDistance > radius) {
      if (!widget.settings.activityBoundary.alertOnExit) return;

      ToastUtil.show(context, '경고: 활동 구역을 벗어났습니다!', isError: true);

      // TODO: 필요 시 서버에 이탈 로그 전송 (Direct DB Guide에 따르면 필수는 아님)
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;

          final interval =
              widget.settings.locationPolicy.revealIntervalSec ?? 0;
          if (interval > 0) {
            _nextRevealSeconds--;
            if (_nextRevealSeconds <= 0) {
              _updateOpponentSnapshots();
              _showLocationReveal();
              _nextRevealSeconds = interval;
            }
          }
        });
        _startTimer();
      }
    });
  }

  void _updateOpponentSnapshots() {
    if (_latestStatuses.isEmpty) return;

    final newSnapshots = <String, LatLng>{};
    for (final s in _latestStatuses) {
      if (s.uid == _myId) continue;
      if (s.role != widget.role) {
        newSnapshots[s.uid] = s.position;
      }
    }

    // 이 메서드는 Timer나 Listener 내부의 setState에서 호출되므로
    // 별도의 setState 호출이 필요 없거나, 호출된 문맥에 따라 다름.
    // Timer에서는 setState 내부이므로 그냥 변수 할당만 해도 됨.
    // Listener에서는 외부이므로 setState 필요.
    // 안전하게, 호출처에서 setState를 하거나,
    // 여기서 setState를 할 때 mounted 체크 필요.
    // 현재 구조상 Timer -> setState -> call function 이므로 변수 업데이트만 하면 됨.
    // Listener -> call function 이므로 거기서는 setState 필요하지 않을까?
    // Listener 코드:
    // _updateOpponentSnapshots();
    // _hasInitialSnapshot = true;
    // 그리고 Listener는 setState 내부는 아님.

    // 따라서 여기서 setState를 하는게 안전하지만, Timer 내부 호출 시 중복 setState 이슈가 있을 수 있음.
    // 하지만 setState는 중첩 호출되어도 에러나지 않음 (단, build 동안 호출되면 에러).
    // Timer 구조: setState( () { ... call ... } )
    // 여기서 또 setState를 부르면 안됨!

    // Strategy: Just update the map reference here.
    // The caller (Timer/Listener) is responsible for triggering rebuild if needed.
    // BUT! Listener didn't wrapping it in setState.

    _visibleOpponentLocations = newSnapshots;
  }

  void _showLocationReveal() {
    setState(() => _showingLocationAlert = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showingLocationAlert = false);
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isThief = widget.role == TeamRole.thief;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Show Game Menu on Back Press
        _showGameMenu(context, isThief);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false, // 키보드 올라와도 배경 유지
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              // 1. 지도 영역 (전체 화면)
              Positioned.fill(child: _buildMapArea(isThief)),

              // 2. 어두운 오버레이 (키보드나 팝업 시 배경 강조용, 필요시 사용)
              // ...

              // 3. 상단 헤더 (Floating)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: _buildHeader(isThief),
              ),

              // 4. 채팅 오버레이 (좌측 하단)
              Positioned(
                left: 16,
                bottom:
                    100 + MediaQuery.of(context).viewInsets.bottom, // 키보드 위로 이동
                child: _buildChatOverlay(),
              ),

              // 5. 하단 버튼/입력창 (Floating)
              Positioned(
                left: 16,
                right: 16,
                bottom:
                    MediaQuery.of(context).padding.bottom +
                    16 +
                    MediaQuery.of(context).viewInsets.bottom, // 키보드 위로 이동
                child: _buildBottomButtons(isThief),
              ),

              // 6. 기타 플로팅 버튼들
              if (_showingLocationAlert) _buildLocationAlert(),
              if (_speakingNickname != null) _buildVoiceOverlay(),
              if (widget.settings.gameMode == 'advanced') ...[
                if (isThief) _buildCaughtButton(),
                if (isThief) _buildRescueButton(),
                if (!isThief) _buildArrestButton(),
              ],
              _buildMyLocationButton(),
              _buildVoiceButton(isThief),
              _buildChatScreenButton(isThief), // 채팅 버튼 분리
            ],
          ), // Stack
        ), // GestureDetector
      ), // Scaffold
    ); // PopScope
  }

  Widget _buildChatScreenButton(bool isThief) {
    return Positioned(
      bottom: 90 + MediaQuery.of(context).viewInsets.bottom, // 키보드 대응 및 위치 조정
      right: 16,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                roomId: widget.roomId,
                userRole: widget.role,
                title: '채팅',
                isTeamChat: true,
                themeColor: isThief ? AppColors.thief : AppColors.police,
              ),
            ),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            color: isThief ? AppColors.thief : AppColors.police,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isThief) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 좌측: 역할 + 타이머 캡슐
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isThief ? AppColors.thief : AppColors.police,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(isThief ? '🏃' : '👮', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 16,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.timer, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // 우측: 잡은 수 + 메뉴
        Row(
          children: [
            // 잡은 수 캡슐
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Theme.of(context).iconTheme.color,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_capturedThieves/$_totalThieves',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 메뉴 버튼
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => _showGameMenu(context, isThief),
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).iconTheme.color,
                ),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapArea(bool isThief) {
    return StreamBuilder<RoomModel>(
      initialData: context.read<RoomService>().getRoom(widget.roomId),
      stream: context.read<RoomService>().getRoomStream(widget.roomId),
      builder: (context, roomSnapshot) {
        final participants = roomSnapshot.data?.participants ?? {};

        return StreamBuilder<List<LiveStatusModel>>(
          stream: _statusStream,
          builder: (context, snapshot) {
            final livePlayers = snapshot.data ?? [];

            // Convert to PlayerMarkerData
            final markers = livePlayers
                .where((p) {
                  if (p.uid == _myId) return false;

                  // 1. 같은 팀이면 무조건 표시
                  if (p.role == widget.role) return true;

                  // 2. 상대 팀이면 설정에 따라 표시
                  final policy = widget.settings.locationPolicy;
                  bool canSee = false;
                  if (widget.role == TeamRole.police) {
                    canSee = policy.policeCanSeeThieves;
                  } else {
                    canSee = policy.thievesCanSeePolice;
                  }

                  if (!canSee) return false;

                  // 3. 주기적 공개 모드일 경우, 스냅샷 데이터가 없으면 표시 안 함
                  final interval = policy.revealIntervalSec ?? 0;
                  if (interval > 0) {
                    return _visibleOpponentLocations.containsKey(p.uid);
                  }

                  return true;
                })
                .map((p) {
                  final nickname = participants[p.uid]?.nickname ?? 'Unknown';

                  // 위치 결정 (상대팀 & 주기적 공개면 스냅샷 사용)
                  LatLng displayPos = p.position;
                  if (p.role != widget.role) {
                    final interval =
                        widget.settings.locationPolicy.revealIntervalSec ?? 0;
                    if (interval > 0 &&
                        _visibleOpponentLocations.containsKey(p.uid)) {
                      displayPos = _visibleOpponentLocations[p.uid]!;
                    }
                  }

                  return PlayerMarkerData(
                    id: p.uid,
                    nickname: nickname,
                    position: displayPos,
                    isPolice: p.role == TeamRole.police,
                    isCaptured: p.state == PlayerState.captured,
                  );
                })
                .toList();

            return FlutterMapWidget(
              initialPosition: _currentPosition,
              overlayCenter: LatLng(
                widget.settings.activityBoundary.centerLat,
                widget.settings.activityBoundary.centerLng,
              ),
              jailPosition: LatLng(
                widget.settings.prisonLocation.lat,
                widget.settings.prisonLocation.lng,
              ),
              circleRadius: widget.settings.activityBoundary.radiusMeter
                  .toDouble(),
              showCircleOverlay: true,
              showMyLocation: true,
              playerMarkers: markers,
              onMapReady: (controller) {
                _mapController = controller;
              },
              onMapTap: (point) {
                FocusScope.of(context).unfocus();
                debugPrint('Map tapped at: $point');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatOverlay() {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 180),
      child: StreamBuilder<List<ChatMessage>>(
        stream: context.read<ChatService>().getMessagesStream(widget.roomId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          // 최신순으로 정렬된 메시지 가져오기
          final allMessages = snapshot.data!;
          // 내 팀에 맞는 메시지만 필터링 (전체 + 내 팀)
          final filteredMessages = allMessages.where((msg) {
            if (msg.type == ChatType.global) return true;
            if (msg.type == ChatType.team && msg.team == widget.role) {
              return true;
            }
            return false;
          }).toList();

          // 최근 5개만 표시
          final recentMessages = filteredMessages.length > 5
              ? filteredMessages.sublist(filteredMessages.length - 5)
              : filteredMessages;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: recentMessages.map((message) {
              final isGlobal = message.type == ChatType.global;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: isGlobal ? '[전체] ' : '[팀] ',
                        style: TextStyle(
                          color: isGlobal
                              ? Colors.orangeAccent
                              : (widget.role == TeamRole.police
                                    ? AppColors.police
                                    : AppColors.thief),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: '${message.senderName}: ',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: message.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    // GamePlayScreen에서의 빠른 채팅은 기본적으로 'Team' 채팅으로 전송
    context.read<ChatService>().sendMessage(
      roomId: widget.roomId,
      uid: user.uid,
      nickname: user.nickname,
      message: text.trim(),
      type: ChatType.team,
      team: widget.role,
    );

    setState(() {
      _chatController.clear();
      _isComposing = false;
    });
  }

  Widget _buildBottomButtons(bool isThief) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 16),
              child: TextField(
                controller: _chatController,
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.trim().isNotEmpty;
                  });
                },
                onSubmitted: _sendMessage,
                decoration: const InputDecoration(
                  hintText: '메시지 입력...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (_isComposing)
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _sendMessage(_chatController.text),
                icon: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 20,
                ),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 250 + MediaQuery.of(context).viewInsets.bottom,
      right: 16,
      child: GestureDetector(
        onTap: () {
          // 기존 Move 로직 대신 CameraFit 사용
          // _mapController.move(_currentPosition, 16.0);

          final center = LatLng(
            widget.settings.activityBoundary.centerLat,
            widget.settings.activityBoundary.centerLng,
          );
          final radius = widget.settings.activityBoundary.radiusMeter
              .toDouble();

          // Calculate bounds for circle
          // (Simple approximation or use Distance class if exact is needed,
          // but here we can reuse the logic from MapPreview or just use Distance)
          const distance = Distance();
          final north = distance.offset(center, radius, 0);
          final east = distance.offset(center, radius, 90);
          final south = distance.offset(center, radius, 180);
          final west = distance.offset(center, radius, 270);

          final bounds = LatLngBounds.fromPoints([north, east, south, west]);

          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.my_location, color: Colors.blueAccent),
        ),
      ),
    );
  }

  void _showGameMenu(BuildContext context, bool isThief) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '게임 메뉴',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('계속하기'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('설정'),
                onTap: () => Navigator.pop(context),
              ),
              if (widget.isHost)
                ListTile(
                  leading: const Icon(
                    Icons.stop_circle_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    '게임 종료',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEndGameDialog();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('도움말'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.flag, color: AppColors.danger),
                title: const Text(
                  '게임 포기',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showGiveUpDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCaughtQrDialog() {
    if (_myId == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.caughtQrTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                color: Colors.white,
                child: QrImageView(
                  data: _myId!,
                  version: QrVersions.auto,
                  gapless: false,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.caughtQrDesc,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArrestScanner() {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1000, // 1초 간격으로 스캔 (중복 방지)
      returnImage: false,
      formats: [BarcodeFormat.qrCode],
      autoStart: true,
      torchEnabled: false,
    );

    bool isProcessing = false;

    // 화면 중앙의 스캔 영역 계산 (250x250)
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 250,
      height: 250,
    );

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            MobileScanner(
              controller: controller,
              scanWindow: scanWindow, // 스캔 영역 제한
              onDetect: (capture) {
                if (isProcessing) return;

                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  debugPrint('QR Scan Detected: $code');

                  if (code != null) {
                    isProcessing = true;
                    controller.stop();
                    Navigator.pop(dialogContext);
                    debugPrint('Handling arrest for target: $code');
                    _handleArrest(code);
                    break;
                  }
                }
              },
              errorBuilder: (context, error, child) {
                return Center(
                  child: Text(
                    '카메라 오류: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Text(
                    AppStrings.scanQrTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppStrings.scanQrGuide,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  controller.dispose();
                  Navigator.pop(dialogContext);
                },
              ),
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.police, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  Future<void> _handleArrest(String targetId) async {
    if (_myId == null) return;

    debugPrint('Attempting arrest -> Police: $_myId, Target: $targetId');
    LoadingUtil.show(context, message: AppStrings.checkingResult);

    try {
      final success = await context.read<GamePlayService>().attemptCapture(
        roomId: widget.roomId,
        policeId: _myId!,
        targetThiefId: targetId,
      );

      debugPrint('Arrest result: $success');

      if (mounted) LoadingUtil.hide(context);

      if (success) {
        if (mounted) ToastUtil.show(context, AppStrings.arrestSuccess);
      } else {
        if (mounted)
          ToastUtil.show(context, AppStrings.arrestFail, isError: true);
      }
    } catch (e) {
      debugPrint('Arrest error: $e');
      if (mounted) LoadingUtil.hide(context);
      if (mounted) ToastUtil.show(context, '오류: $e', isError: true);
    }
  }

  Widget _buildRescueButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 140,
      right: 16,
      child: GestureDetector(
        onTap: _showRescueScanner,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.qr_code_scanner, color: Colors.white),
              SizedBox(width: 8),
              Text(
                '구출하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRescueScanner() {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1000,
      returnImage: false,
      formats: [BarcodeFormat.qrCode],
      autoStart: true,
      torchEnabled: false,
    );

    bool isProcessing = false;

    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 250,
      height: 250,
    );

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            MobileScanner(
              controller: controller,
              scanWindow: scanWindow,
              onDetect: (capture) {
                if (isProcessing) return;

                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  debugPrint('Rescue Scan Detected: $code');

                  if (code != null) {
                    isProcessing = true;
                    controller.stop();
                    Navigator.pop(dialogContext);
                    _handleRescue(code);
                    break;
                  }
                }
              },
              errorBuilder: (context, error, child) {
                return Center(
                  child: Text(
                    '카메라 오류: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Text(
                    '동료 구출 스캔',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '감옥에 있는 동료의 QR 코드를 스캔하세요',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  controller.dispose();
                  Navigator.pop(dialogContext);
                },
              ),
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  Future<void> _handleRescue(String targetId) async {
    if (_myId == null) return;

    LoadingUtil.show(context, message: '구출 시도 중...');

    try {
      final success = await context.read<GamePlayService>().attemptRescue(
        roomId: widget.roomId,
        rescuerId: _myId!,
        targetThiefId: targetId,
      );

      if (mounted) LoadingUtil.hide(context);

      if (success) {
        if (mounted) ToastUtil.show(context, '구출 성공!');
      } else {
        if (mounted)
          ToastUtil.show(context, '구출 실패: 거리가 멀거나 이미 구출되었습니다.', isError: true);
      }
    } catch (e) {
      if (mounted) LoadingUtil.hide(context);
      if (mounted) ToastUtil.show(context, '오류: $e', isError: true);
    }
  }

  void _showGiveUpDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('게임 포기'),
        content: const Text('정말 게임을 포기하시겠습니까?\n홈 화면으로 이동하며 방에서 퇴장합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('아니요'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              // Show Loading
              LoadingUtil.show(context, message: '퇴장 처리 중...');

              // Capture services using the widget's context (safe if widget is mounted)
              if (!mounted) return;
              final roomService = context.read<RoomService>();

              // 1. 방 퇴장 요청
              try {
                if (_myId != null) {
                  await roomService.leaveRoom(widget.roomId, _myId!);
                }
              } catch (e) {
                // Hide loading on error (though we force exit anyway)
                if (mounted) {
                  // LoadingUtil.hide(context); // We navigate away anyway, but explicit hide helps if Toast needs to be seen?
                  // Actually, we process exit regardless of error usually?
                  // Original code: showed toast on error, then navigated.
                  LoadingUtil.hide(context);
                  ToastUtil.show(
                    context,
                    '방 퇴장 중 오류가 발생했습니다: $e',
                    isError: true,
                  );
                  // We should probably NOT continue to home if leave failed?
                  // But typically user wants to force leave.
                  // Let's stick to original logic: try leave, then go home.
                  // Re-show loading or just keep it?
                  // If we hide it to show Toast, we should probably not navigate immediately if we want user to see Toast.
                  // But 'Show Loading' covers the screen.
                  // Let's just catch, show toast, and continue.
                }
              }

              // 2. 홈으로 이동
              if (mounted) {
                // No need to hide loading manually if we are replacing the route
                // But cleaning up is good practice if pushAndRemoveUntil differs.
                // pushAndRemoveUntil wipes everything.
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('예'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton(bool isThief) {
    return Positioned(
      bottom: 160 + MediaQuery.of(context).viewInsets.bottom, // 키보드 대응 및 위치 조정
      right: 16,
      child: Listener(
        onPointerDown: (_) {
          debugPrint('PTT Button: Down');
          setState(() => _isTalking = true);
          context.read<VoiceService>().startRecording(
            widget.roomId,
            widget.role,
          );
        },
        onPointerUp: (_) {
          debugPrint('PTT Button: Up');
          setState(() => _isTalking = false);
          if (_myId != null) {
            final user = context.read<AuthService>().currentUser;
            if (user != null) {
              context.read<VoiceService>().stopRecording(
                widget.roomId,
                user.uid,
                user.nickname,
                widget.role,
              );
            }
          }
        },
        onPointerCancel: (_) {
          setState(() => _isTalking = false);
          final user = context.read<AuthService>().currentUser;
          if (user != null) {
            context.read<VoiceService>().stopRecording(
              widget.roomId,
              user.uid,
              user.nickname,
              widget.role,
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), // 반응 속도 빠르게
          width: _isTalking ? 80 : 70, // 누를 때 커지는 효과
          height: _isTalking ? 80 : 70,
          decoration: BoxDecoration(
            color: _isTalking
                ? Colors.redAccent
                : (isThief ? AppColors.thief : AppColors.police),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              if (_isTalking)
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 8,
                ),
            ],
            border: Border.all(color: Colors.white, width: _isTalking ? 4 : 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isTalking ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 32,
              ),
              if (!_isTalking)
                const Text(
                  'HOLD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationAlert() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 150, // 헤더 및 버튼 아래로 이동
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.refresh, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '상대방 위치 정보 갱신됨',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCaughtButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80, // 헤더 아래 적절한 위치
      right: 16,
      child: GestureDetector(
        onTap: _showCaughtQrDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.back_hand, color: Colors.white),
              SizedBox(width: 8),
              Text(
                '잡혔어요',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrestButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      right: 16,
      child: GestureDetector(
        onTap: _showArrestScanner,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.police,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.qr_code_scanner, color: Colors.white),
              SizedBox(width: 8),
              Text(
                AppStrings.arrestButton,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOverlay() {
    return Positioned(
      top: 100,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              '$_speakingNickname 무전 중...',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CaughtScreen extends StatelessWidget {
  final GameSystemRules settings;
  const CaughtScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.danger.withOpacity(0.1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sentiment_dissatisfied,
                size: 100,
                color: AppColors.danger,
              ),
              const SizedBox(height: 24),
              const Text(
                '💀 붙잡혔습니다!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '경찰에게 잡혔습니다',
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.police,
                        child: Icon(
                          Icons.local_police,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '잡은 경찰',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const Text(
                        '경찰1',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildRecordRow('생존 시간', '12분 30초'),
                      const Divider(),
                      _buildRecordRow('이동 거리', '1.2km'),
                      const Divider(),
                      _buildRecordRow('순위', '2/3'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat),
                      label: const Text('채팅 보기'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
