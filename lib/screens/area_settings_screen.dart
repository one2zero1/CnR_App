import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import 'room_created_screen.dart';

class AreaSettingsScreen extends StatefulWidget {
  final String gameName;
  final int playTime;
  final int locationInterval;
  final int captureDistance;

  const AreaSettingsScreen({
    super.key,
    required this.gameName,
    required this.playTime,
    required this.locationInterval,
    required this.captureDistance,
  });

  @override
  State<AreaSettingsScreen> createState() => _AreaSettingsScreenState();
}

class _AreaSettingsScreenState extends State<AreaSettingsScreen> {
  double _radius = 300;
  LatLng _centerPosition = const LatLng(37.5665, 126.9780); // 서울 시청 기본값
  MapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _centerPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _updateMapCamera();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('위치 가져오기 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateMapCamera() {
    _mapController?.move(_centerPosition, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('놀이 영역 설정'),
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
                // flutter_map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _centerPosition,
                    initialZoom: 16.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _centerPosition = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.gyeong_do',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _centerPosition,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                  ],
                ),
                // 로딩 인디케이터
                if (_isLoading)
                  Container(
                    color: Colors.white.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('현재 위치를 가져오는 중...'),
                        ],
                      ),
                    ),
                  ),
                // 안내 텍스트
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
                        Icon(Icons.touch_app, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          '놀이 영역 중심을 터치하세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '반경 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '반경: ${_radius.toInt()}m',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '100m',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                    Expanded(
                      child: Slider(
                        value: _radius,
                        min: 100,
                        max: 1000,
                        divisions: 18,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _radius = value;
                          });
                        },
                      ),
                    ),
                    const Text(
                      '1000m',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final roomCode = _generateRoomCode();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomCreatedScreen(
                          roomCode: roomCode,
                          gameName: widget.gameName,
                          playTime: widget.playTime,
                          locationInterval: widget.locationInterval,
                          captureDistance: widget.captureDistance,
                          radius: _radius.toInt(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 8),
                      Text('영역 확정', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) {
      return chars[(DateTime.now().millisecondsSinceEpoch + index * 7) %
          chars.length];
    }).join();
  }
}
