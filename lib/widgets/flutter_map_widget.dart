import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

class FlutterMapWidget extends StatefulWidget {
  final LatLng? initialPosition;
  final LatLng? overlayCenter; // 오버레이 중심 좌표
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
  Widget build(BuildContext context) {
    final center = widget.initialPosition ?? LatLng(37.5665, 126.9780);

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
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                color: AppColors.primary.withValues(alpha: 0.2),
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
                    color: AppColors.thief,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
  final bool isMe;

  PlayerMarkerData({
    required this.id,
    required this.nickname,
    required this.position,
    required this.isPolice,
    this.isMe = false,
  });
}
