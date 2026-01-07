import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/flutter_map_widget.dart';
import 'chat_screen.dart';
import 'spectator_screen.dart';
import '../models/game_types.dart';
import 'move_to_jail_screen.dart';

class GamePlayScreen extends StatefulWidget {
  final TeamRole role;
  final String gameName;

  const GamePlayScreen({super.key, required this.role, required this.gameName});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  int _remainingSeconds = 600; // 10분
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

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    // 권한 확인 (area_settings_screen에서 이미 받았겠지만 안전을 위해)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // 초기 위치 한 번 가져오기
      try {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
        }
      } catch (e) {
        debugPrint('초기 위치 가져오기 실패: $e');
      }

      // 위치 스트림 시작
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, // 2미터마다 업데이트
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = LatLng(
                  position.latitude,
                  position.longitude,
                );
              });
              // TODO: 서버로 내 위치 전송 (Socket.io)
            }
          });
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
          ],
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
    return FlutterMapWidget(
      initialPosition: _currentPosition,
      overlayCenter: const LatLng(37.5665, 126.9780), // 게임 영역 중심 고정
      jailPosition: const LatLng(37.5668, 126.9782), // 감옥 위치 (테스트)
      circleRadius: 300,
      showCircleOverlay: true,
      showMyLocation: true,
      playerMarkers: [
        // 테스트용 더미 데이터
        PlayerMarkerData(
          id: '1',
          nickname: '도둑1',
          position: const LatLng(37.5670, 126.9785),
          isPolice: false,
        ),
        PlayerMarkerData(
          id: '2',
          nickname: '경찰1',
          position: const LatLng(37.5660, 126.9775),
          isPolice: true,
        ),
      ],
      onMapTap: (point) {
        // 지도 터치 시 동작
        debugPrint('Map tapped at: $point');
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
            )
          else
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      title: isThief ? '팀 채팅 (도둑)' : '팀 채팅 (경찰)',
                      isTeamChat: true,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[600]),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '게임 메뉴',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
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
                  builder: (_) => const MoveToJailScreen(
                    jailPosition: LatLng(
                      37.5668,
                      126.9782,
                    ), // TODO: 실제 감옥 위치 사용
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
                  builder: (_) => SpectatorScreen(gameName: widget.gameName),
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
  const CaughtScreen({super.key});

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
                            builder: (_) =>
                                const SpectatorScreen(gameName: '게임'),
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
