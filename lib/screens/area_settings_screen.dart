import 'dart:math'; // Random
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
  LatLng? _myLocation; // 실제 내 위치
  MapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
          _centerPosition = _myLocation!; // 초기엔 내 위치를 중심으로
          _isLoading = false;
        });
        _moveToMyLocation();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('위치 가져오기 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  void _moveToMyLocation() {
    if (_myLocation != null && _mapController != null) {
      _mapController!.move(_myLocation!, 16);
      setState(() {
        _centerPosition = _myLocation!; // 내 위치로 돌아오면 영역 중심도 내 위치로 리셋? (선택사항)
        // 사용자가 "내 위치 보기"만 원할수도 있으므로 _centerPosition은 건드리지 않는게 나을 수 있지만,
        // 보통 초기 세팅 화면에서는 내 위치 주변을 잡고 싶어하므로 업데이트 함. (여기선 업데이트)
      });
    }
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
                    // 영역 표시
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _centerPosition,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withOpacity(0.2),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                    // 내 위치 마커
                    if (_myLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _myLocation!,
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue, // 내 위치는 파란색
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    // 영역 중심 아이콘 (드래그 대신 탭으로 이동하므로 시각적 피드백)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _centerPosition,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 40,
                          ),
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
                        Expanded(
                          child: Text(
                            '지도를 터치하여 놀이 영역의 중심을 설정하세요.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 현재 위치로 이동 버튼
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _moveToMyLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
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
                  const Text(
                    '영역 크기 (반경)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _radius,
                          min: 50,
                          max: 1000,
                          divisions: 19,
                          label: '${_radius.toInt()}m',
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              _radius = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_radius.toInt()}m',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      final roomCode = (100000 + Random().nextInt(900000))
                          .toString();
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '설정 완료',
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
