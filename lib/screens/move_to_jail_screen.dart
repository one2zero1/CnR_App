import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../theme/app_sizes.dart';
import '../config/app_strings.dart';
import 'in_jail_screen.dart';
import 'game_result_screen.dart';
import '../models/game_types.dart';
import '../models/room_model.dart';
import '../models/live_status_model.dart';
import 'game_play_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/game_play_service.dart';

class MoveToJailScreen extends StatefulWidget {
  final LatLng jailPosition;
  final String roomId;
  final TeamRole role;
  final GameSystemRules settings;
  final bool isHost;

  const MoveToJailScreen({
    super.key,
    required this.jailPosition,
    required this.roomId,
    required this.role,
    required this.settings,
    required this.isHost,
  });

  @override
  State<MoveToJailScreen> createState() => _MoveToJailScreenState();
}

class _MoveToJailScreenState extends State<MoveToJailScreen> {
  LatLng _currentPosition = const LatLng(37.5665, 126.9780);
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<LiveStatusModel>>? _statusSubscription;
  double _distanceToJail = 0;
  final Distance _distance = const Distance();
  String? _myId;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _myId = authService.currentUser?.uid;
    _startLocationUpdates();
    _startStatusListener();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  void _startStatusListener() {
    if (_myId == null) return;

    final gamePlayService = context.read<GamePlayService>();
    _statusSubscription = gamePlayService
        .getLiveStatusesStream(widget.roomId)
        .listen((statuses) {
          if (!mounted) return;
          try {
            final myStatus = statuses.firstWhere((s) => s.uid == _myId);

            // 만약 상태가 normal로 변경되면 (구출됨)
            if (myStatus.state == PlayerState.normal) {
              _statusSubscription?.cancel();

              // 이동 화면 종료 -> 게임 화면으로 복귀
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GamePlayScreen(
                      gameName:
                          '경찰과 도둑', // TODO: Pass actual game name if available
                      roomId: widget.roomId,
                      role: widget.role,
                      settings: widget.settings,
                      isHost: widget.isHost,
                    ),
                  ),
                );
              }
            }
          } catch (_) {}
        });
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
      _updateServerLocation(_currentPosition);
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

  @override
  Widget build(BuildContext context) {
    final bool isArrived = _distanceToJail < 20.0; // 20m 이내 도착 간주

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.cantGoBack),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.moveToJailTitle),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.danger,
          foregroundColor: AppColors.surface,
          actions: [
            TextButton.icon(
              onPressed: _showGiveUpDialog,
              icon: const Icon(Icons.flag, color: AppColors.surface),
              label: const Text(
                AppStrings.giveUp,
                style: TextStyle(color: AppColors.surface),
              ),
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
                          color: AppColors.surface,
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
              top: AppSizes.paddingMedium,
              left: AppSizes.paddingMedium,
              right: AppSizes.paddingMedium,
              child: Card(
                color: AppColors.danger,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    children: [
                      const Text(
                        AppStrings.arrestedTitle,
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceSmall),
                      const Text(
                        AppStrings.arrestedContent,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceLarge),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMedium,
                          vertical: AppSizes.paddingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.2,
                          ), // Keeping opacity on white/generic for transparency over danger color
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          // Use simple string concat for now instead of complex formatter
                          '남은 거리: ${_distanceToJail.toInt()}m',
                          style: const TextStyle(
                            color: AppColors.surface,
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
              bottom: AppSizes.paddingXLarge,
              left: AppSizes.paddingLarge,
              right: AppSizes.paddingLarge,
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
                              settings: widget.settings,
                              isHost: widget.isHost,
                            ),
                          ),
                        );
                      }
                    : null, // 거리가 멀면 비활성화
                style: ElevatedButton.styleFrom(
                  backgroundColor: isArrived ? AppColors.police : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  ),
                ),
                child: Text(
                  isArrived ? AppStrings.enterJail : AppStrings.moveToJailGuide,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
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
        title: const Text(AppStrings.giveUpTitle),
        content: const Text(AppStrings.giveUpContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GameResultScreen(
                    gameName: '경찰과 도둑',
                    roomId: widget.roomId,
                  ), // TODO: 실제 게임 이름 전달
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(AppStrings.giveUpConfirm),
          ),
        ],
      ),
    );
  }
}
