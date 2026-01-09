import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/room_model.dart'; // For GameSettings
import 'chat_screen.dart';
import 'spectator_screen.dart';
import 'game_result_screen.dart';
import '../models/game_types.dart';

class InJailScreen extends StatefulWidget {
  final String gameName;
  final String roomId;
  final TeamRole role;
  final GameSystemRules settings;

  const InJailScreen({
    super.key,
    required this.gameName,
    required this.roomId,
    required this.role,
    required this.settings,
  });

  @override
  State<InJailScreen> createState() => _InJailScreenState();
}

class _InJailScreenState extends State<InJailScreen> {
  int _secondsInJail = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsInJail++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('감옥에 수감 중입니다. 나갈 수 없습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          title: const Text('감옥'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
              onPressed: _showGiveUpDialog,
              icon: const Icon(Icons.flag, color: Colors.white),
              label: const Text('포기', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // 감옥 아이콘 및 상태
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade700, width: 4),
                  color: Colors.grey.shade800,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 80, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      '수감 중',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 수감 시간
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    const Text(
                      '수감 시간',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(_secondsInJail),
                      style: const TextStyle(
                        color: AppColors.timerText,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '동료가 구출해주기를 기다리세요...',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const Spacer(),
              // 하단 버튼
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpectatorScreen(
                                gameName: widget.gameName,
                                settings: widget.settings, // Pass settings
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('관전하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                title: '팀 채팅',
                                isTeamChat: true,
                                roomId: widget.roomId,
                                userRole: widget.role,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('구조 요청'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.thief,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _showGiveUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게임 포기'),
        content: const Text('정말 게임을 포기하시겠습니까?\n포기하면 결과 화면으로 이동합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GameResultScreen(gameName: widget.gameName),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('포기하기'),
          ),
        ],
      ),
    );
  }
}
