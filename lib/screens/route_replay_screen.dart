import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RouteReplayScreen extends StatefulWidget {
  const RouteReplayScreen({super.key});

  @override
  State<RouteReplayScreen> createState() => _RouteReplayScreenState();
}

class _RouteReplayScreenState extends State<RouteReplayScreen> {
  bool _isPlaying = false;
  double _progress = 0.0;
  double _playbackSpeed = 1.0;

  final Map<String, bool> _visiblePlayers = {
    '경찰1': true,
    '경찰2': true,
    '도둑1': true,
    '도둑2': true,
  };

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _startPlayback();
    }
  }

  void _startPlayback() {
    Future.delayed(Duration(milliseconds: (100 / _playbackSpeed).round()), () {
      if (mounted && _isPlaying && _progress < 1.0) {
        setState(() {
          _progress += 0.01;
        });
        _startPlayback();
      } else if (_progress >= 1.0) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  String _formatTime(double progress) {
    final totalSeconds = (30 * 60 * progress).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이동 경로'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMapArea()),
          _buildPlaybackControls(),
          _buildPlayerSelection(),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFE8E8E8),
          child: CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(),
          ),
        ),
        // 영역 경계선
        Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 3,
              ),
            ),
          ),
        ),
        // 경로 라인들
        if (_visiblePlayers['경찰1']!)
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(
              color: AppColors.police,
              progress: _progress,
              offsetX: 50,
              offsetY: 30,
            ),
          ),
        if (_visiblePlayers['경찰2']!)
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(
              color: AppColors.policeLight,
              progress: _progress,
              offsetX: -30,
              offsetY: -50,
            ),
          ),
        if (_visiblePlayers['도둑1']!)
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(
              color: AppColors.thief,
              progress: _progress,
              offsetX: 80,
              offsetY: -20,
            ),
          ),
        if (_visiblePlayers['도둑2']!)
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(
              color: AppColors.thiefLight,
              progress: _progress,
              offsetX: -60,
              offsetY: 40,
            ),
          ),
        // 현재 위치 마커들
        ..._buildCurrentPositionMarkers(),
      ],
    );
  }

  List<Widget> _buildCurrentPositionMarkers() {
    final List<Widget> markers = [];

    if (_visiblePlayers['경찰1']!) {
      markers.add(
        Positioned(
          left: 100 + (_progress * 150),
          top: 200 - (_progress * 50),
          child: _PlayerMarker(color: AppColors.police, label: '👮'),
        ),
      );
    }

    if (_visiblePlayers['경찰2']!) {
      markers.add(
        Positioned(
          right: 100 - (_progress * 80),
          top: 180 + (_progress * 30),
          child: _PlayerMarker(color: AppColors.policeLight, label: '👮'),
        ),
      );
    }

    if (_visiblePlayers['도둑1']!) {
      markers.add(
        Positioned(
          left: 150 + (_progress * 100),
          bottom: 200 - (_progress * 80),
          child: _PlayerMarker(color: AppColors.thief, label: '🏃'),
        ),
      );
    }

    if (_visiblePlayers['도둑2']!) {
      markers.add(
        Positioned(
          right: 150 + (_progress * 50),
          bottom: 250 - (_progress * 100),
          child: _PlayerMarker(color: AppColors.thiefLight, label: '🏃'),
        ),
      );
    }

    return markers;
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _formatTime(_progress),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _progress,
                  onChanged: (value) {
                    setState(() {
                      _progress = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              const Text(
                '30:00',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _progress = 0;
                    _isPlaying = false;
                  });
                },
                icon: const Icon(Icons.replay),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                onPressed: _togglePlayback,
                backgroundColor: AppColors.primary,
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<double>(
                initialValue: _playbackSpeed,
                onSelected: (value) {
                  setState(() {
                    _playbackSpeed = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 1.0, child: Text('1x')),
                  const PopupMenuItem(value: 2.0, child: Text('2x')),
                  const PopupMenuItem(value: 5.0, child: Text('5x')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textHint),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_playbackSpeed.toInt()}x',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '표시할 플레이어',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _visiblePlayers.entries.map((entry) {
              final isPolice = entry.key.contains('경찰');
              return FilterChip(
                selected: entry.value,
                label: Text(entry.key),
                avatar: Icon(
                  isPolice ? Icons.local_police : Icons.directions_run,
                  size: 18,
                  color: entry.value
                      ? (isPolice ? AppColors.police : AppColors.thief)
                      : AppColors.textHint,
                ),
                onSelected: (selected) {
                  setState(() {
                    _visiblePlayers[entry.key] = selected;
                  });
                },
                selectedColor: isPolice
                    ? AppColors.police.withOpacity(0.2)
                    : AppColors.thief.withOpacity(0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('스크린샷이 저장되었습니다')),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('스크린샷'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
        ),
      ),
    );
  }
}

class _PlayerMarker extends StatelessWidget {
  final Color color;
  final String label;

  const _PlayerMarker({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  final Color color;
  final double progress;
  final double offsetX;
  final double offsetY;

  _RoutePainter({
    required this.color,
    required this.progress,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerX = size.width / 2 + offsetX;
    final centerY = size.height / 2 + offsetY;

    path.moveTo(centerX, centerY);

    final points = [
      Offset(centerX + 30, centerY - 20),
      Offset(centerX + 60, centerY + 10),
      Offset(centerX + 40, centerY + 50),
      Offset(centerX + 80, centerY + 30),
      Offset(centerX + 100, centerY - 10),
    ];

    for (var point in points) {
      path.lineTo(point.dx, point.dy);
    }

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
