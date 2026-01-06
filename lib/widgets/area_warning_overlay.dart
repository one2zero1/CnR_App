import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AreaWarningOverlay extends StatefulWidget {
  final int remainingSeconds;
  final VoidCallback? onDismiss;

  const AreaWarningOverlay({
    super.key,
    required this.remainingSeconds,
    this.onDismiss,
  });

  @override
  State<AreaWarningOverlay> createState() => _AreaWarningOverlayState();
}

class _AreaWarningOverlayState extends State<AreaWarningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                      size: 100,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '놀이 영역을 벗어났습니다!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.danger, width: 2),
                ),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Text(
                          '${widget.remainingSeconds}',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                            shadows: [
                              Shadow(
                                color: AppColors.danger.withOpacity(0.5),
                                blurRadius: _pulseAnimation.value * 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Text(
                      '초 내 복귀하세요',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '미복귀 시 위치가 실시간으로 공개됩니다!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.danger,
                    width: 4,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.danger.withOpacity(0.1),
                      ),
                    ),
                    const Icon(
                      Icons.my_location,
                      color: AppColors.thief,
                      size: 24,
                    ),
                    Positioned(
                      left: 60,
                      top: 40,
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.success,
                        size: 32,
                      ),
                    ),
                    const Positioned(
                      bottom: 20,
                      child: Text(
                        '복귀 방향',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
