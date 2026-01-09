import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../models/game_types.dart';
import '../../../models/room_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/room_service.dart';
import '../../waiting_room_screen.dart';

class Step6Jail extends StatefulWidget {
  final String gameName;
  final int playTime;
  final int locationInterval;
  final RoleAssignmentMethod roleMethod;
  final LatLng centerPosition;
  final int radius;
  final LatLng? initialJailPosition;
  final ValueChanged<LatLng> onJailSelected;

  const Step6Jail({
    super.key,
    required this.gameName,
    required this.playTime,
    required this.locationInterval,
    required this.roleMethod,
    required this.centerPosition,
    required this.radius,
    required this.initialJailPosition,
    required this.onJailSelected,
  });

  @override
  State<Step6Jail> createState() => _Step6JailState();
}

class _Step6JailState extends State<Step6Jail> {
  final Distance _distance = const Distance();
  bool _isLoading = false;

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (widget.initialJailPosition != null) {
      // Allow re-selection
    }

    final distance = _distance.as(
      LengthUnit.Meter,
      widget.centerPosition,
      point,
    );
    if (distance <= widget.radius) {
      widget.onJailSelected(point);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('감옥은 설정된 놀이 영역 안에 있어야 합니다.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _createGame() async {
    if (widget.initialJailPosition == null) return;

    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final roomService = context.read<RoomService>();

      var user = authService.currentUser;
      if (user == null) {
        user = await authService.signInAnonymously('Host');
      }

      final rules = GameSystemRules(
        gameDurationSec: (widget.playTime * 60).toInt(),
        minPlayers: 4,
        maxPlayers: 10,
        policeCount: 1,
        roleAssignmentMode: widget.roleMethod.name,
        activityBoundary: ActivityBoundary(
          centerLat: widget.centerPosition.latitude,
          centerLng: widget.centerPosition.longitude,
          radiusMeter: widget.radius,
          alertOnExit: true,
        ),
        prisonLocation: PrisonLocation(
          lat: widget.initialJailPosition!.latitude,
          lng: widget.initialJailPosition!.longitude,
          radiusMeter: 20,
        ),
        locationPolicy: LocationPolicy(
          revealMode: 'always',
          isGpsHighAccuracy: true,
          policeCanSeeThieves: true,
          thievesCanSeePolice: false,
          revealIntervalSec: (widget.locationInterval * 60).toInt(),
        ),
        captureRules: CaptureRules(
          triggerDistanceMeter: 3,
          requireButtonPress: true,
          captureCooldownSec: 10,
          validateOnServer: false,
        ),
        releaseRules: ReleaseRules(
          triggerDistanceMeter: 5,
          releaseDurationSec: 5,
          interruptible: true,
          interruptDistanceMeter: 10,
        ),
        victoryConditions: VictoryConditions(
          policeWin: 'all_thieves_captured',
          thiefWin: 'time_limit',
        ),
      );

      final creationResult = await roomService.createRoom(
        hostId: user.uid,
        rules: rules,
      );

      await roomService.joinRoom(pinCode: creationResult.pinCode, user: user);

      if (!mounted) return;

      // Close Wizard and navigate to Waiting Room
      // Since we pushed PageView context, we actually need to replace the whole Wizard screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(
            roomId: creationResult.roomId,
            roomCode: creationResult.pinCode,
            isHost: true,
            gameName: widget.gameName,
            roleMethod: widget.roleMethod,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('방 생성 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: widget.centerPosition,
                  initialZoom: 16.0,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.gyeong_do',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: widget.centerPosition,
                        radius: widget.radius.toDouble(),
                        useRadiusInMeter: true,
                        color: AppColors.primary.withOpacity(0.1),
                        borderColor: AppColors.primary,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  if (widget.initialJailPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.initialJailPosition!,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.police,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(blurRadius: 4, color: Colors.black26),
                              ],
                            ),
                            child: const Icon(
                              Icons.grid_view,
                              color: AppColors.police,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: const Text(
                    '영역 내부를 터치하여 감옥 위치를 지정하세요.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: widget.initialJailPosition != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.initialJailPosition != null
                          ? '감옥 위치가 설정되었습니다'
                          : '감옥 위치를 선택해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.initialJailPosition != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: widget.initialJailPosition != null && !_isLoading
                      ? _createGame
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '게임 생성하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
