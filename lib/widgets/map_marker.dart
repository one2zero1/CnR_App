import 'package:flutter/material.dart';

class MapMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;
  final bool showShadow;
  final double borderWidth;

  const MapMarker({
    super.key,
    required this.color,
    required this.icon,
    this.size = 40.0,
    this.showShadow = true,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: borderWidth),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.6, // 아이콘 크기는 마커 크기의 60%
      ),
    );
  }
}
