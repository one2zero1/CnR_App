import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

class FlutterMapWidget extends StatefulWidget {
  final LatLng? initialPosition;
  final LatLng? overlayCenter; // 오버레이 중심 좌표
  final LatLng? jailPosition; // 감옥 위치
  final double? circleRadius;
  final bool showMyLocation;
  final bool showCircleOverlay;
  final List<PlayerMarkerData> playerMarkers;
  final Function(LatLng)? onMapTap;
  final Function(MapController)? onMapReady;

  const FlutterMapWidget({
    super.key,
    this.initialPosition,
    this.circleRadius,
    this.overlayCenter, // 오버레이 중심 (옵션)
    this.jailPosition,
    this.showMyLocation = true,
    this.showCircleOverlay = false,
    this.playerMarkers = const [],
    this.onMapTap,
    this.onMapReady,
  });

  @override
  State<FlutterMapWidget> createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // onMapReady 콜백 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapReady?.call(_mapController);
    });
  }

  @override
  void didUpdateWidget(covariant FlutterMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPosition != null &&
        widget.initialPosition != oldWidget.initialPosition) {
      // 위치가 변경되면 지도를 해당 위치로 이동 (Follow Me)
      _mapController.move(widget.initialPosition!, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialPosition ?? const LatLng(37.5665, 126.9780);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
        onTap: (tapPosition, point) => widget.onMapTap?.call(point),
      ),
      children: [
        // 지도 타일 레이어 (OpenStreetMap)
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.gyeong_do',
        ),

        // 원형 오버레이
        if (widget.showCircleOverlay && widget.circleRadius != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.overlayCenter ?? center,
                radius: widget.circleRadius!,
                useRadiusInMeter: true,
                color: AppColors.primary.withOpacity(0.2),
                borderColor: AppColors.primary,
                borderStrokeWidth: 3,
              ),
            ],
          ),

        // 플레이어 마커들
        if (widget.playerMarkers.isNotEmpty)
          MarkerLayer(
            markers: widget.playerMarkers.map((markerData) {
              return Marker(
                point: markerData.position,
                width: 40,
                height: 70,
                child: Column(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: markerData.isPolice
                          ? AppColors.police
                          : AppColors.thief,
                      size: 40,
                    ),
                    if (markerData.nickname.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: markerData.isPolice
                                ? AppColors.police
                                : AppColors.thief,
                          ),
                        ),
                        child: Text(
                          markerData.nickname,
                          style: TextStyle(
                            fontSize: 10,
                            color: markerData.isPolice
                                ? AppColors.police
                                : AppColors.thief,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),

        // 내 위치 마커
        if (widget.showMyLocation)
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue, // 내 위치는 파란색
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
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

        // 감옥 마커
        if (widget.jailPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.jailPosition!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.police, width: 2),
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
                    Icons.grid_view,
                    color: AppColors.police,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class PlayerMarkerData {
  final String id;
  final String nickname;
  final LatLng position;
  final bool isPolice;
  final bool isCaptured;

  PlayerMarkerData({
    required this.id,
    required this.nickname,
    required this.position,
    required this.isPolice,
    this.isCaptured = false,
  });
}
