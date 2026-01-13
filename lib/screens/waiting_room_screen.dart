import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart'; // Exports AppColors
import '../config/app_strings.dart';
import '../theme/app_sizes.dart';
import 'game_play_screen.dart';
import 'chat_screen.dart';
import 'map_preview_screen.dart';
import '../models/game_types.dart';
import '../models/room_model.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import '../services/authority_service.dart';
import '../utils/loading_util.dart'; // Import Loading Util
import '../utils/toast_util.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomId; // 실제 Room UUID (API 통신용)
  final String roomCode; // 표시용 PIN Code
  final bool isHost;
  final String gameName;
  final RoleAssignmentMethod roleMethod;

  const WaitingRoomScreen({
    super.key,
    required this.roomId,
    required this.roomCode,
    required this.isHost,
    required this.gameName,
    this.roleMethod = RoleAssignmentMethod.manual,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  late Stream<RoomModel> _roomStream;
  String? _myId;
  final Map<String, TeamRole> _optimisticRoles = {}; // Optimistic UI state
  bool _isNavigating = false;
  bool _isStartingGame =
      false; // Flag to track if we are in "Starting Game" loading state

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final roomService = context.read<RoomService>();
    _myId = authService.currentUser?.uid;
    _roomStream = roomService.getRoomStream(widget.roomId); // UUID 사용

    // Auto-ready for everyone
    if (_myId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        roomService
            .updateMyStatus(roomId: widget.roomId, uid: _myId!, isReady: true)
            .catchError((e) {
              debugPrint('Failed to auto-ready: $e');
            });
      });
    }
  }

  Future<void> _changeRole(RoomModel room, TeamRole newRole) async {
    if (_myId == null) return;

    // Optimistic Update
    setState(() {
      _optimisticRoles[_myId!] = newRole;
    });

    try {
      await context.read<RoomService>().updateMyStatus(
        roomId: room.roomId,
        uid: _myId!,
        team: newRole,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _optimisticRoles.remove(_myId!);
      });
      _showError('${AppStrings.changeTeamFailed}$e');
    }
  }

  Future<void> _startGame(RoomModel room) async {
    if (!widget.isHost) return;

    // 1. 미배정 인원 확인
    final hasUnassigned = room.participants.values.any(
      (p) => p.team == 'unassigned',
    );
    if (hasUnassigned) {
      ToastUtil.show(context, '모든 플레이어가 팀을 정해야 합니다.', isError: true);
      return;
    }

    // 2. 경찰 인원 확인 (최소 1명)
    final policeCount = room.participants.values
        .where((p) => p.team == 'police')
        .length;
    if (policeCount < 1) {
      ToastUtil.show(context, '경찰이 최소 1명 필요합니다.', isError: true);
      return;
    }

    // 3. 준비 완료 확인 (호스트 제외 전원 Ready)
    // 호스트는 준비 완료 상태가 아니어도 됨 (시작 버튼이 준비 완료임)
    // 하지만 데이터상으로는 호스트도 참여자 리스트에 있으므로, 호스트가 아닌 참여자들만 체크
    final nonHostParticipants = room.participants.entries.where(
      (e) => e.key != room.sessionInfo.hostId,
    );
    final notReadyCount = nonHostParticipants
        .where((e) => !e.value.ready)
        .length;

    if (notReadyCount > 0) {
      ToastUtil.show(context, '모든 플레이어가 준비 완료 상태여야 합니다.', isError: true);
      return;
    }

    // Show Loading
    LoadingUtil.show(context, message: '게임을 시작하는 중...');
    setState(() => _isStartingGame = true);

    try {
      await context.read<RoomService>().startGame(room.roomId);
      // Success: Do NOT hide loading here.
      // The stream update (status='playing') will trigger the navigation logic
      // in build(), which will handle hiding the dialog.
    } catch (e) {
      // Failure: Must hide loading and reset flag
      if (mounted) {
        LoadingUtil.hide(context);
        setState(() => _isStartingGame = false);
      }
      ToastUtil.show(context, '${AppStrings.startGameFailed}$e', isError: true);
    }
  }

  Future<void> _leaveRoom(String roomId) async {
    if (_myId == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.surface),
      ),
    );

    try {
      await context.read<RoomService>().leaveRoom(roomId, _myId!);
      if (!mounted) return;
      // Pop loading dialog then nav back
      Navigator.of(context).pop();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Pop loading
      _showError('${AppStrings.leaveRoomFailed}$e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLeaveDialog(String roomId) {
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
              _leaveRoom(roomId); // Start leaving logic
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(AppStrings.leaveRoom),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RoomModel>(
      stream: _roomStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('${AppStrings.errorGeneric}: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final room = snapshot.data!;

        if (room.sessionInfo.status == 'playing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isNavigating) return;
            _isNavigating = true;

            // If we showed a loading dialog for game start, hide it now
            if (_isStartingGame) {
              LoadingUtil.hide(context);
              // We don't necessarily need to set _isStartingGame = false since we are navigating away
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GamePlayScreen(
                  role: TeamRole.values.firstWhere(
                    (e) =>
                        e.name ==
                        (room.participants[_myId]?.team ?? 'unassigned'),
                    orElse: () => TeamRole.unassigned,
                  ),
                  gameName: widget.gameName,
                  roomId: room.roomId,
                  settings:
                      room.gameSystemRules, // Pass rules instead of settings
                  isHost: _myId == room.sessionInfo.hostId,
                ),
              ),
            );
          });
        }

        final players = room.participants.entries.map((e) {
          // Optimistic role override
          TeamRole displayRole;
          if (_optimisticRoles.containsKey(e.key)) {
            displayRole = _optimisticRoles[e.key]!;
          } else {
            displayRole = TeamRole.values.firstWhere(
              (r) => r.name == e.value.team,
              orElse: () => TeamRole.unassigned,
            );
          }

          return PlayerUIModel(
            id: e.key,
            nickname: e.value.nickname,
            role: displayRole,
            isReady: e.value.ready,
            isHost: e.key == room.sessionInfo.hostId,
            joinedAt: e.value.joinedAt,
          );
        }).toList();

        // Sort players
        players.sort((a, b) {
          // 1. Host always top
          if (a.isHost) return -1;
          if (b.isHost) return 1;

          // 2. Me (if not host) next
          if (a.id == _myId) return -1;
          if (b.id == _myId) return 1;

          // 3. Joined time (ascending)
          return a.joinedAt.compareTo(b.joinedAt);
        });

        final amIHost = _myId == room.sessionInfo.hostId;
        final myPlayer = room.participants[_myId];
        final iAmReady = myPlayer?.ready ?? false;

        final theme = Theme.of(context);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _showLeaveDialog(widget.roomId);
          },
          child: Scaffold(
            // Use inherited theme background
            appBar: AppBar(
              title: Text(widget.gameName),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
              leading: InkWell(
                onTap: () => _showLeaveDialog(widget.roomId),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  margin: const EdgeInsets.all(AppSizes.paddingSmall),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: AppSizes.paddingSmall),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MapPreviewScreen(settings: room.gameSystemRules),
                        ),
                      );
                    },
                    icon: Icon(Icons.map, color: theme.colorScheme.onSurface),
                    tooltip: '지도 확인', // TODO: Add to strings
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // settings
                  },
                  icon: Icon(
                    Icons.settings,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                _buildHeader(room.sessionInfo.pinCode, players.length),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLarge,
                      0,
                      AppSizes.paddingLarge,
                      AppSizes.paddingLarge,
                    ),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      return _buildPlayerCard(players[index], amIHost, room);
                    },
                  ),
                ),
                _buildBottomArea(
                  amIHost,
                  iAmReady,
                  room,
                  TeamRole.values.firstWhere(
                    (e) => e.name == (myPlayer?.team ?? 'unassigned'),
                    orElse: () => TeamRole.unassigned,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String roomCode, int playerCount) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingLarge),
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.roomCode,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: AppSizes.spaceSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                roomCode,
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: AppSizes.spaceMedium),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.codeCopied)),
                  );
                },
                icon: const Icon(Icons.copy, color: AppColors.surface),
                tooltip: AppStrings.copyCodeTooltip,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: AppSizes.spaceMedium),
              InkWell(
                onTap: () => _showQRCodeDialog(roomCode),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.surface.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.qr_code, color: AppColors.surface),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, color: AppColors.surface, size: 16),
                const SizedBox(width: 4),
                Text(
                  // AppStrings.playerCountFormat doesn't support direct formatting here without sprintf logic or just manual string interpolation
                  // Manual for now: '현재 인원 $playerCount/8명'
                  '현재 인원 $playerCount/8명',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.qrCodeTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: AppColors.surface,
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              Text(
                'CODE: $code',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text(AppStrings.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(PlayerUIModel player, bool amIHost, RoomModel room) {
    final theme = Theme.of(context);
    final isMe = player.id == _myId;
    final isPolice = player.role == TeamRole.police;
    final roleColor = isPolice ? AppColors.police : AppColors.thief;

    final card = Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceMedium),
      decoration: BoxDecoration(
        color: theme.cardTheme.color, // Use theme card color
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Slightly stronger shadow
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: roleColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: roleColor.withOpacity(
                    0.2,
                  ), // Increased opacity
                  child: Icon(Icons.person, color: roleColor, size: 28),
                ),
                if (player.isHost)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 10,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSizes.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        player.nickname,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface, // Adaptive color
                        ),
                      ),
                      if (isMe)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            AppStrings.meTag,
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (player.isReady)
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          AppStrings.readyStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      AppStrings.waitingStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (_canModifyRole(player, isMe, amIHost))
              _buildRoleToggle(player, room)
            else
              _buildRoleDisplay(player),
          ],
        ),
      ),
    );
    // If host and not self, wrap with GestureDetector for options
    if (amIHost && !isMe) {
      return GestureDetector(
        onLongPress: () =>
            _showHostOptions(player.id, player.nickname, room.roomId),
        child: card,
      );
    }
    return card;
  }

  void _showHostOptions(String targetId, String nickname, String roomId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              '$nickname 관리', // TODO: Use AppStrings.manageUserFormat with simple replace or interpolation
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: AppColors.policeLight),
            title: const Text(AppStrings.forceChangeRole),
            onTap: () {
              Navigator.pop(context);
              _showRoleChangeDialog(targetId, roomId);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.remove_circle_outline,
              color: AppColors.danger,
            ),
            title: const Text(AppStrings.kickUser),
            onTap: () {
              Navigator.pop(context);
              _kickUser(targetId, roomId);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _kickUser(String targetId, String roomId) async {
    try {
      await context.read<AuthorityService>().kickUser(roomId, _myId!, targetId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.userKicked)));
    } catch (e) {
      _showError('${AppStrings.kickUserFailed}$e');
    }
  }

  void _showRoleChangeDialog(String targetId, String roomId) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(AppStrings.selectRole),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _forceRoleChange(targetId, roomId, 'police');
            },
            child: const Text(AppStrings.rolePolice),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _forceRoleChange(targetId, roomId, 'thief');
            },
            child: const Text(AppStrings.roleThief),
          ),
        ],
      ),
    );
  }

  Future<void> _forceRoleChange(
    String targetId,
    String roomId,
    String newRole,
  ) async {
    try {
      await context.read<AuthorityService>().forceChangeRole(
        roomId,
        _myId!,
        targetId,
        newRole,
      );
    } catch (e) {
      _showError('${AppStrings.changeRoleFailed}$e');
    }
  }

  bool _canModifyRole(PlayerUIModel player, bool isMe, bool amIHost) {
    if (widget.roleMethod == RoleAssignmentMethod.random) return false;
    if (isMe) return true;
    if (widget.roleMethod == RoleAssignmentMethod.host && amIHost) return true;
    return false;
  }

  Widget _buildRoleToggle(PlayerUIModel player, RoomModel room) {
    final isPolice = player.role == TeamRole.police;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _changeRole(room, TeamRole.police),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isPolice ? AppColors.police : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isPolice
                    ? [
                        BoxShadow(
                          color: AppColors.police.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                '👮',
                style: TextStyle(
                  fontSize: 16,
                  color: isPolice ? AppColors.surface : AppColors.textHint,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _changeRole(room, TeamRole.thief),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: !isPolice ? AppColors.thief : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: !isPolice
                    ? [
                        BoxShadow(
                          color: AppColors.thief.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                '🏃',
                style: TextStyle(
                  fontSize: 16,
                  color: !isPolice ? AppColors.surface : AppColors.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDisplay(PlayerUIModel player) {
    if (widget.roleMethod == RoleAssignmentMethod.random) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              Theme.of(context).inputDecorationTheme.fillColor ??
              Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          AppStrings.roleUnknown,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: player.role == TeamRole.police
            ? AppColors.police.withOpacity(0.1)
            : AppColors.thief.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        player.role == TeamRole.police
            ? AppStrings.rolePolice
            : AppStrings.roleThief,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: player.role == TeamRole.police
              ? AppColors.police
              : AppColors.thief,
        ),
      ),
    );
  }

  Widget _buildBottomArea(
    bool amIHost,
    bool iAmReady,
    RoomModel room,
    TeamRole myRole,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    roomId: widget.roomId,
                    userRole: TeamRole.unassigned,
                    title: AppStrings.chatTitle,
                    isTeamChat: false, // Global only in waiting room
                    enableTeamChat: false,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor ?? Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: theme.iconTheme.color ?? AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.spaceMedium),
                  Expanded(
                    child: Text(
                      AppStrings.joinChat,
                      style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color:
                        theme.iconTheme.color?.withOpacity(0.5) ??
                        AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spaceMedium),
          if (amIHost)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startGame(room),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.success.withOpacity(0.5),
                ),
                child: const Text(
                  AppStrings.gameStart,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.read<RoomService>().updateMyStatus(
                    roomId: room.roomId,
                    uid: _myId!,
                    isReady: !iAmReady,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: iAmReady ? Colors.grey : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                child: Text(
                  iAmReady ? AppStrings.unready : AppStrings.ready,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PlayerUIModel {
  final String id;
  final String nickname;
  final TeamRole role;
  final bool isReady;
  final bool isHost;
  final int joinedAt;

  PlayerUIModel({
    required this.id,
    required this.nickname,
    required this.role,
    required this.isReady,
    required this.isHost,
    this.joinedAt = 0,
  });
}
