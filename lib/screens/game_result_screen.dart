import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../models/game_types.dart';
import '../services/room_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'waiting_room_screen.dart';
import '../utils/loading_util.dart'; // Import Loading Util
import '../config/app_strings.dart';

class GameResultScreen extends StatefulWidget {
  final String gameName;
  final bool isHostEnded;
  final String? winnerTeam; // 'Police' or 'Thief'
  final String roomId; // Added roomId

  const GameResultScreen({
    super.key,
    required this.gameName,
    this.isHostEnded = false,
    this.winnerTeam,
    required this.roomId, // Required
  });

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  Future<void> _handleLeaveRoom() async {
    // Show Loading
    LoadingUtil.show(context, message: '퇴장 처리 중...');

    final user = context.read<AuthService>().currentUser;
    // leaveRoom 호출
    if (user != null) {
      try {
        await context.read<RoomService>().leaveRoom(widget.roomId, user.uid);
      } catch (e) {
        // 에러 무시 혹은 로그
        debugPrint('Error leaving room: $e');
      }
    }

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.leaveRoomTitle),
        content: const Text(AppStrings.leaveRoomContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirm dialog
              _handleLeaveRoom();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text(AppStrings.leaveRoom),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        body: SafeArea(
          child: StreamBuilder<RoomModel>(
            stream: context.read<RoomService>().getRoomStream(widget.roomId),
            initialData: context.read<RoomService>().getRoom(widget.roomId),
            builder: (context, snapshot) {
              final room = snapshot.data;
              if (room != null) {
                debugPrint(
                  'DEBUG: GameResultScreen room status: ${room.sessionInfo.status}',
                );
              }
              final isWaiting = room?.sessionInfo.status == 'waiting';

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildHeader(),
                  const Spacer(),
                  _buildBottomButtons(context, isWaiting, room),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = '게임 종료';
    String message = '결과를 확인하세요';
    Color iconColor = Colors.amber;
    IconData icon = Icons.emoji_events;

    if (widget.isHostEnded) {
      title = '게임 종료';
      message = '호스트가 게임을 종료했습니다.';
      icon = Icons.cancel;
      iconColor = Colors.redAccent;
    } else if (widget.winnerTeam != null) {
      final isPoliceWin = widget.winnerTeam == 'Police';
      title = isPoliceWin ? '👮 경찰 승리!' : '🏃 도둑 승리!';
      message = isPoliceWin ? '경찰이 승리 했습니다' : '도둑이 승리 했습니다';
      iconColor = isPoliceWin ? AppColors.police : AppColors.thief;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 80),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    bool isWaiting,
    RoomModel? room,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          if (isWaiting)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (room == null) return;

                  final user = context.read<AuthService>().currentUser;
                  final isHost = room.sessionInfo.hostId == user?.uid;

                  RoleAssignmentMethod roleMethod;
                  switch (room.gameSystemRules.roleAssignmentMode) {
                    case 'host':
                      roleMethod = RoleAssignmentMethod.host;
                      break;
                    case 'random':
                      roleMethod = RoleAssignmentMethod.random;
                      break;
                    case 'manual':
                    default:
                      roleMethod = RoleAssignmentMethod.manual;
                  }

                  context.read<RoomService>().disposeRoom(room.roomId);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WaitingRoomScreen(
                        roomId: room.roomId,
                        roomCode: room.sessionInfo.pinCode,
                        isHost: isHost,
                        gameName: widget.gameName,
                        roleMethod: roleMethod,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('대기실로 이동'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _handleLeaveRoom,
            icon: const Icon(Icons.home),
            label: const Text('홈으로 이동'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
