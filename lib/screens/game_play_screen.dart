import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/flutter_map_widget.dart';
import 'waiting_room_screen.dart';
import 'chat_screen.dart';
import 'spectator_screen.dart';

class GamePlayScreen extends StatefulWidget {
  final PlayerRole role;
  final String gameName;

  const GamePlayScreen({super.key, required this.role, required this.gameName});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  int _remainingSeconds = 600; // 10분
  int _nextRevealSeconds = 180; // 3분
  bool _showingLocationAlert = false;
  bool _isTalking = false; // 무전기 상태 (PTT)
  int _survivorCount = 3;
  int _myCaptureCount = 0;

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
    final isThief = widget.role == PlayerRole.thief;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게임 중에는 뒤로 갈 수 없습니다. 게임 종료 버튼을 이용해주세요.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(isThief),
                Expanded(child: _buildMapArea(isThief)),
                _buildInfoPanel(isThief),
                _buildBottomButtons(isThief),
              ],
            ),
            if (_showingLocationAlert) _buildLocationAlert(),
            _buildVoiceButton(isThief),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isThief) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: isThief ? AppColors.thief : AppColors.police,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  isThief ? '🏃 도둑' : '👮 경찰',
                  style: TextStyle(
                    color: isThief ? AppColors.thief : AppColors.police,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showGameMenu(context),
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea(bool isThief) {
    return FlutterMapWidget(
      initialPosition: _currentPosition,
      overlayCenter: const LatLng(37.5665, 126.9780), // 게임 영역 중심 고정
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

  Widget _buildInfoPanel(bool isThief) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.timer,
                label: '다음 위치 공개',
                value: _formatTime(_nextRevealSeconds),
                color: AppColors.warning,
              ),
              if (isThief)
                _buildInfoItem(
                  icon: Icons.people,
                  label: '생존자',
                  value: '$_survivorCount명',
                  color: AppColors.success,
                )
              else
                _buildInfoItem(
                  icon: Icons.catching_pokemon,
                  label: '내 포획',
                  value: '$_myCaptureCount명',
                  color: AppColors.police,
                ),
              _buildInfoItem(
                icon: isThief ? Icons.shield : Icons.directions_run,
                label: isThief ? '남은 도둑' : '남은 도둑',
                value: '$_survivorCount명',
                color: isThief ? AppColors.thief : AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.safe.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.safe, size: 20),
                const SizedBox(width: 8),
                Text(
                  isThief ? '안전 영역 내' : '추적 중...',
                  style: TextStyle(
                    color: AppColors.safe,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(bool isThief) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          if (isThief)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showCaughtDialog(),
                icon: const Icon(Icons.close),
                label: const Text('잡혔어요'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          else
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.near_me),
                label: const Text('가장 가까운 도둑'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.police,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          const SizedBox(width: 8),
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
            icon: const Icon(Icons.chat),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.my_location),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
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

  void _showGameMenu(BuildContext context) {
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
                MaterialPageRoute(builder: (_) => const CaughtScreen()),
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
      bottom: 220, // 텍스트 가림 방지를 위해 위치 상향 조정
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isTalking = !_isTalking;
          });
          // TODO: 음성 전송 상태 변경 (WebRTC 연동)
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 70, // 고정 크기 또는 약간의 변화
          height: 70,
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
                  color: Colors.redAccent.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
            ],
            border: Border.all(color: Colors.white, width: _isTalking ? 4 : 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isTalking ? Icons.mic : Icons.mic_off, // 아이콘 변경
                color: Colors.white,
                size: 32,
              ),
              Text(
                _isTalking ? 'ON' : 'OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
