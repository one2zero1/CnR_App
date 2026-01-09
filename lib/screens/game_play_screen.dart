import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/flutter_map_widget.dart';
import 'chat_screen.dart';
import 'spectator_screen.dart';
import '../models/game_types.dart';
import '../models/room_model.dart'; // For GameSettings
import '../models/live_status_model.dart';
import 'move_to_jail_screen.dart';
import '../services/game_play_service.dart';
import '../services/auth_service.dart';

class GamePlayScreen extends StatefulWidget {
  final TeamRole role;
  final String gameName;
  final String roomId;
  final GameSystemRules settings;
  const GamePlayScreen({
    super.key,
    required this.role,
    required this.gameName,
    required this.roomId,
    required this.settings,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  int _remainingSeconds = 600; // Will be init in initState
  int _nextRevealSeconds = 180; // 3분
  bool _showingLocationAlert = false;
  bool _showingExitWarning = false; // 뒤로가기 경고 상태
  bool _isTalking = false; // 무전기 상태 (PTT)
  int _myCaptureCount = 0;

  // 채팅 관련
  final List<String> _recentMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isComposing = false;

  // 위치 관련
  LatLng _currentPosition = const LatLng(37.5665, 126.9780);
  StreamSubscription<Position>? _positionStream;
  Stream<List<LiveStatusModel>>? _statusStream;
  String? _myId;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _myId = authService.currentUser?.uid;
    final gamePlayService = context.read<GamePlayService>();

    _statusStream = gamePlayService.getLiveStatusesStream(widget.roomId);

    _remainingSeconds = widget.settings.gameDurationSec; // Init time limit
    _startTimer();
    _startLocationUpdates();
  }

  @override
  void dispose() {
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

  Future<void> _checkBoundary(LatLng pos) async {
    if (_myId == null) return;
    final result = await context.read<GamePlayService>().checkBoundary(
      roomId: widget.roomId,
      uid: _myId!,
      position: pos,
    );
    if (result != null && !result.isWithinBoundary && !_showingExitWarning) {
      // Using 'Exit Warning' logic for Boundary check for now, or add specific alert
      // _showingExitWarning is for Back Button preventing.
      // Let's repurpose or add boundary alert.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('경고: 활동 구역을 벗어났습니다!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _nextRevealSeconds--;
          if (_nextRevealSeconds <= 0) {
            _showLocationReveal();
            _nextRevealSeconds = 180;
          }
        });
        _startTimer();
      }
    });
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
        // 커스텀 경고 메시지 표시
        if (!_showingExitWarning) {
          setState(() => _showingExitWarning = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _showingExitWarning = false);
            }
          });
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false, // 키보드 올라와도 배경 유지
        body: Stack(
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
            if (_showingLocationAlert)
              Positioned.fill(child: _buildLocationAlert()),
            if (_showingExitWarning) _buildExitWarningToast(),
            if (isThief) _buildCaughtButton(),
            _buildVoiceButton(isThief),
            _buildChatScreenButton(isThief), // 채팅 버튼 분리
          ],
        ),
      ),
    );
  }

  Widget _buildChatScreenButton(bool isThief) {
    return Positioned(
      bottom: 140 + MediaQuery.of(context).viewInsets.bottom, // 키보드 올라오면 같이 이동
      right: 16,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                roomId: widget.roomId,
                userRole: widget.role,
                title: isThief ? '팀 채팅 (도둑)' : '팀 채팅 (경찰)',
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
            color: Colors.white,
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
                color: Colors.white.withOpacity(0.9),
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
                  Icon(Icons.people, color: Colors.grey[700], size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$_myCaptureCount/3', // TODO: 연동
                    style: TextStyle(
                      color: Colors.grey[800],
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
                color: Colors.white,
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
                icon: const Icon(Icons.menu, color: Colors.black87),
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
    return StreamBuilder<List<LiveStatusModel>>(
      stream: _statusStream,
      builder: (context, snapshot) {
        final livePlayers = snapshot.data ?? [];

        // Convert to PlayerMarkerData
        final markers = livePlayers.where((p) => p.uid != _myId).map((p) {
          return PlayerMarkerData(
            id: p.uid,
            nickname:
                'Player', // TODO: Fetch nicknames? LiveStatusModel doesn't have nickname yet.
            position: p.position,
            isPolice: p.role == TeamRole.police,
          );
        }).toList();

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
          circleRadius: widget.settings.activityBoundary.radiusMeter.toDouble(),
          showCircleOverlay: true,
          showMyLocation: true,
          playerMarkers: markers,
          onMapTap: (point) {
            debugPrint('Map tapped at: $point');
          },
        );
      },
    );
  }

  Widget _buildChatOverlay() {
    if (_recentMessages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 250,
      constraints: const BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        reverse: true,
        itemCount: _recentMessages.length,
        itemBuilder: (context, index) {
          final message =
              _recentMessages[_recentMessages.length - 1 - index]; // 최신순 반전
          return Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _recentMessages.add('나: $text');
      if (_recentMessages.length > 5) {
        _recentMessages.removeAt(0); // 최근 5개만 유지
      }
      _chatController.clear();
      _isComposing = false;
    });
    // TODO: 실제 채팅 서버 전송 로직 추가
  }

  Widget _buildBottomButtons(bool isThief) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
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
                style: const TextStyle(fontSize: 15),
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

  Widget _buildLocationAlert() {
    return Container(
      color: AppColors.danger.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.white, size: 80),
            SizedBox(height: 16),
            Text(
              '🚨 위치가 공개되었습니다!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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

  void _showCaughtDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정말 잡혔나요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('경찰에게 터치당하셨나요?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '잡은 경찰 선택'),
              items: const [
                DropdownMenuItem(value: 'police1', child: Text('경찰1')),
                DropdownMenuItem(value: 'police2', child: Text('경찰2')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니요, 취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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
                    settings: widget.settings, // Passing rules
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('예, 잡혔어요'),
          ),
        ],
      ),
    );
  }

  void _showGiveUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게임 포기'),
        content: const Text('정말 게임을 포기하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니요'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SpectatorScreen(
                    gameName: widget.gameName,
                    settings: widget.settings, // Pass settings
                  ),
                ),
              );
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
      bottom: 220,
      right: 16,
      child: Listener(
        onPointerDown: (_) {
          setState(() => _isTalking = true);
          // TODO: 음성 전송 시작 (WebRTC 연동)
        },
        onPointerUp: (_) {
          setState(() => _isTalking = false);
          // TODO: 음성 전송 종료
        },
        onPointerCancel: (_) {
          setState(() => _isTalking = false);
          // TODO: 음성 전송 종료
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

  Widget _buildCaughtButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80, // 헤더 아래 적절한 위치
      right: 16,
      child: GestureDetector(
        onTap: _showCaughtDialog,
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

  Widget _buildExitWarningToast() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '뒤로 갈 수 없습니다. 종료 버튼을 이용해주세요.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SpectatorScreen(
                              gameName: '게임',
                              settings: settings, // Pass settings
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('관전 모드'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
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
