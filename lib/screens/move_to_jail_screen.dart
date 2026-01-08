import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import 'in_jail_screen.dart';
import 'game_result_screen.dart';
import '../models/game_types.dart';
import '../models/room_model.dart';

class MoveToJailScreen extends StatefulWidget {
  final LatLng jailPosition;
  final String roomId;
  final TeamRole role;
  final GameSettings settings;

  const MoveToJailScreen({
    super.key,
    required this.jailPosition,
    required this.roomId,
    required this.role,
    required this.settings,
  });

  @override
  State<MoveToJailScreen> createState() => _MoveToJailScreenState();
}

class _MoveToJailScreenState extends State<MoveToJailScreen> {
  LatLng _currentPosition = const LatLng(37.5665, 126.9780);
  StreamSubscription<Position>? _positionStream;
  double _distanceToJail = 0;
  final Distance _distance = const Distance();

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    // 권한은 이미 GamePlayScreen에서 처리되었다고 가정
    try {
      final position = await Geolocator.getCurrentPosition();
      _updatePosition(position);

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(_updatePosition);
    } catch (e) {
      debugPrint('위치 업데이트 실패: $e');
    }
  }

  void _updatePosition(Position position) {
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _distanceToJail = _distance.as(
          LengthUnit.Meter,
          _currentPosition,
          widget.jailPosition,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArrived = _distanceToJail < 20.0; // 20m 이내 도착 간주

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('감옥으로 이동해야 합니다 뒤로 갈 수 없습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('감옥으로 이동'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
              onPressed: _showGiveUpDialog,
              icon: const Icon(Icons.flag, color: Colors.white),
              label: const Text('포기', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 17.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.gyeong_do',
                ),
                // 이동 경로 선 (직선)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_currentPosition, widget.jailPosition],
                      strokeWidth: 4,
                      color: AppColors.danger.withOpacity(0.5),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // 내 위치
                    Marker(
                      point: _currentPosition,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.directions_run,
                        color: AppColors.thief,
                        size: 30,
                      ),
                    ),
                    // 감옥 위치
                    Marker(
                      point: widget.jailPosition,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.police, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.grid_view,
                          color: AppColors.police,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // 상단 안내 메시지
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: AppColors.danger,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        '🚨 체포되었습니다!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '스스로 감옥으로 이동하세요.\n감옥에 도착해야 이후 플레이가 가능합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '남은 거리: ${_distanceToJail.toInt()}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 하단 도착 확인 버튼
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: ElevatedButton(
                onPressed: isArrived
                    ? () {
                        // 감옥 입장 - InJailScreen 이동
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InJailScreen(
                              gameName: '경찰과 도둑',
                              roomId: widget.roomId,
                              role: widget.role,
                              settings: widget.settings, // Passing settings
                            ), // TODO: 실제 게임 이름 전달
                          ),
                        );
                      }
                    : null, // 거리가 멀면 비활성화
                style: ElevatedButton.styleFrom(
                  backgroundColor: isArrived ? AppColors.police : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isArrived ? '감옥 입장하기' : '감옥으로 이동하세요',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiveUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게임 포기'),
        content: const Text('정말 게임을 포기하시겠습니까?\n포기하면 결과 화면으로 이동합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const GameResultScreen(
                    gameName: '경찰과 도둑',
                  ), // TODO: 실제 게임 이름 전달
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('포기하기'),
          ),
        ],
      ),
    );
  }
}
