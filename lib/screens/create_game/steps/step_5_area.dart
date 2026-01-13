import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../theme/app_theme.dart';

class Step5Area extends StatefulWidget {
  final LatLng initialCenter;
  final double initialRadius;
  final Function(LatLng center, double radius) onAreaChanged;
  final ValueChanged<bool>? onLoadingStateChanged;

  const Step5Area({
    super.key,
    required this.initialCenter,
    required this.initialRadius,
    required this.onAreaChanged,
    this.onLoadingStateChanged,
  });

  @override
  State<Step5Area> createState() => _Step5AreaState();
}

class _Step5AreaState extends State<Step5Area> {
  late LatLng _centerPosition;
  late double _radius;
  LatLng? _myLocation;
  MapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _centerPosition = widget.initialCenter;
    _radius = widget.initialRadius;
    _mapController = MapController();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    widget.onLoadingStateChanged?.call(true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (!mounted) return; // Check if widget is still in tree

        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
          // If we are at default value (Seoul), move to my location
          if (widget.initialCenter.latitude == 37.5665 &&
              widget.initialCenter.longitude == 126.9780) {
            _centerPosition = _myLocation!;
            widget.onAreaChanged(_centerPosition, _radius);
          }
          _isLoading = false;
        });
        widget.onLoadingStateChanged?.call(false);
        if (widget.initialCenter.latitude == 37.5665 &&
            widget.initialCenter.longitude == 126.9780) {
          _moveToMyLocation();
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        widget.onLoadingStateChanged?.call(false);
      }
    } catch (e) {
      debugPrint('위치 가져오기 실패: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onLoadingStateChanged?.call(false);
    }
  }

  void _moveToMyLocation() {
    if (_myLocation != null && _mapController != null) {
      _mapController!.move(_myLocation!, 16);
      setState(() {
        _centerPosition = _myLocation!;
        widget.onAreaChanged(_centerPosition, _radius);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Map Area
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _centerPosition,
                  initialZoom: 16.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _centerPosition = point;
                      widget.onAreaChanged(_centerPosition, _radius);
                    });
                  },
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
                        point: _centerPosition,
                        radius: _radius,
                        useRadiusInMeter: true,
                        color: AppColors.primary.withOpacity(0.2),
                        borderColor: AppColors.primary,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  if (_myLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _myLocation!,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(blurRadius: 4, color: Colors.black26),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _centerPosition,
                        width: 30,
                        height: 30,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
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
                    '지도를 터치하여 놀이 영역의 중심을 지정하세요.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: _moveToMyLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        // Settings Area
        Expanded(
          flex: 2,
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
                Text(
                  '놀이 영역 크기 (반경)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${_radius.toInt()}m',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Slider(
                  value: _radius,
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _radius = value;
                      widget.onAreaChanged(_centerPosition, _radius);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
