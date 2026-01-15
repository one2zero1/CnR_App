import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Add Geolocator

import '../models/room_model.dart';
import '../theme/app_theme.dart';
import '../widgets/map_marker.dart';

class MapPreviewScreen extends StatefulWidget {
  final GameSystemRules settings;

  const MapPreviewScreen({super.key, required this.settings});

  @override
  State<MapPreviewScreen> createState() => _MapPreviewScreenState();
}

class _MapPreviewScreenState extends State<MapPreviewScreen> {
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndFetch();
  }

  Future<void> _checkLocationPermissionAndFetch() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('위치 서비스를 활성화해주세요.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('위치 권한이 거부되었습니다.')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해주세요.')),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  // Calculate bounds to fit the circle
  LatLngBounds _calculateBounds(LatLng center, double radiusMeters) {
    // Earth radius in meters
    const earthRadius = 6378137.0;

    final latChange = (radiusMeters / earthRadius) * (180 / math.pi);
    final lngChange =
        (radiusMeters / earthRadius) *
        (180 / math.pi) /
        math.cos(center.latitude * math.pi / 180);

    final southWest = LatLng(
      center.latitude - latChange,
      center.longitude - lngChange,
    );
    final northEast = LatLng(
      center.latitude + latChange,
      center.longitude + lngChange,
    );

    return LatLngBounds(southWest, northEast);
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      widget.settings.activityBoundary.centerLat,
      widget.settings.activityBoundary.centerLng,
    );
    final radius = widget.settings.activityBoundary.radiusMeter.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 지도 확인'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: _calculateBounds(center, radius),
            padding: const EdgeInsets.all(
              50,
            ), // Add some padding so the circle isn't touching edges
          ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.gyeong_do',
          ),
          // Game Area Circle
          CircleLayer(
            circles: [
              CircleMarker(
                point: center,
                radius: radius,
                useRadiusInMeter: true,
                color: AppColors.primary.withOpacity(0.1),
                borderColor: AppColors.primary,
                borderStrokeWidth: 2,
              ),
            ],
          ),
          // Prisoner Location (Jail)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  widget.settings.prisonLocation.lat,
                  widget.settings.prisonLocation.lng,
                ),
                width: 40,
                height: 40,
                child: const MapMarker(
                  color: AppColors.police,
                  icon: Icons.grid_view,
                ),
              ),
              // My Location Marker
              if (_myLocation != null)
                Marker(
                  point: _myLocation!,
                  width: 40,
                  height: 40,
                  child: const MapMarker(
                    color: AppColors.success,
                    icon: Icons.my_location,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
