import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/game_types.dart';
import '../models/room_model.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import 'room_created_screen.dart';

class JailSettingsScreen extends StatefulWidget {
  final String gameName;
  final int playTime;
  final int locationInterval;
  final RoleAssignmentMethod roleMethod;
  final LatLng centerPosition;
  final int radius;

  const JailSettingsScreen({
    super.key,
    required this.gameName,
    required this.playTime,
    required this.locationInterval,
    this.roleMethod = RoleAssignmentMethod.manual,
    required this.centerPosition,
    required this.radius,
  });

  @override
  State<JailSettingsScreen> createState() => _JailSettingsScreenState();
}

class _JailSettingsScreenState extends State<JailSettingsScreen> {
  LatLng? _jailPosition;
  bool _isLoading = false;
  final Distance _distance = const Distance();

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Check if the point is within the radius
    final distance = _distance.as(
      LengthUnit.Meter,
      widget.centerPosition,
      point,
    );
    if (distance <= widget.radius) {
      setState(() {
        _jailPosition = point;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('감옥은 설정된 놀이 영역 안에 있어야 합니다.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감옥 위치 설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
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
                    if (_jailPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _jailPosition!,
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.grid_view, // 창살 느낌의 아이콘
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app, color: AppColors.police),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '영역 내부를 터치하여 감옥 위치를 지정하세요.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
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
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _jailPosition == null
                              ? '감옥 위치를 선택해주세요'
                              : '감옥 위치가 설정되었습니다',
                          style: TextStyle(
                            color: _jailPosition == null
                                ? AppColors.textSecondary
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _jailPosition == null
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              final authService = context.read<AuthService>();
                              final roomService = context.read<RoomService>();

                              var user = authService.currentUser;
                              if (user == null) {
                                user = await authService.signInAnonymously(
                                  'Host',
                                );
                              }

                              final settings = GameSettings(
                                timeLimit: widget.playTime * 60,
                                areaRadius: widget.radius,
                                center: widget.centerPosition,
                                jail: _jailPosition!,
                                roleMethod: widget.roleMethod,
                              );

                              final creationResult = await roomService
                                  .createRoom(
                                    hostId: user.uid,
                                    settings: settings,
                                  );

                              // Host needs to join the room using the PIN
                              await roomService.joinRoom(
                                pinCode: creationResult.pinCode,
                                user: user,
                              );

                              if (!mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomCreatedScreen(
                                    roomId: creationResult.roomId,
                                    roomCode: creationResult.pinCode,
                                    gameName: widget.gameName,
                                    playTime: widget.playTime,
                                    locationInterval: widget.locationInterval,
                                    roleMethod: widget.roleMethod,
                                    radius: widget.radius,
                                    centerPosition: widget.centerPosition,
                                    jailPosition: _jailPosition!,
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('방 생성 실패: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade300,
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
                            '최종 생성',
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
      ),
    );
  }
}
