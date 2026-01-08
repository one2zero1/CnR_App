import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/room_model.dart';
import '../theme/app_theme.dart';

class MapPreviewScreen extends StatelessWidget {
  final GameSettings settings;

  const MapPreviewScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 지도 확인'),
        centerTitle: true,
        // backgroundColor: Colors.white, // Removed
        // foregroundColor: Colors.black, // Removed
        elevation: 0,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: settings.center,
          initialZoom: 16.0,
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
                point: settings.center,
                radius: settings.areaRadius.toDouble(),
                useRadiusInMeter: true,
                color: AppColors.primary.withOpacity(0.1),
                borderColor: AppColors.primary,
                borderStrokeWidth: 2,
              ),
            ],
          ),
          // Jail Marker
          MarkerLayer(
            markers: [
              Marker(
                point: settings.jail,
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
    );
  }
}
