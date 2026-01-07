import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import 'game_play_screen.dart';
import 'chat_screen.dart';
import '../models/game_types.dart';

class Player {
  final String id;
  final String nickname;
  TeamRole role;
  bool isReady;
  bool isHost;

  Player({
    required this.id,
    required this.nickname,
    this.role = TeamRole.thief,
    this.isReady = false,
    this.isHost = false,
  });
}

class WaitingRoomScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final String gameName;
  final RoleAssignmentMethod roleMethod;

  const WaitingRoomScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
    required this.gameName,
    this.roleMethod = RoleAssignmentMethod.manual,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  late List<Player> _players;
  bool _isReady = false;

  // For random mode
  int _policeCount = 1;

  @override
  void initState() {
    super.initState();
    _players = [
      Player(
        id: '1',
        nickname: '나',
        role: TeamRole.police,
        isHost: widget.isHost,
        isReady: true,
      ),
      Player(id: '2', nickname: '플레이어2', role: TeamRole.thief, isReady: true),
      Player(id: '3', nickname: '플레이어3', role: TeamRole.thief, isReady: false),
    ];
  }

  bool get _allReady => _players.every((p) => p.isReady);

  void _toggleReady() {
    setState(() {
      _isReady = !_isReady;
      _players.firstWhere((p) => p.id == '1').isReady = _isReady;
    });
  }

  void _startGame() {
    if (_allReady) {
      if (widget.roleMethod == RoleAssignmentMethod.random) {
        final random = math.Random();
        List<Player> shuffled = List.from(_players)..shuffle(random);
        for (int i = 0; i < shuffled.length; i++) {
          shuffled[i].role = i < _policeCount
              ? TeamRole.police
              : TeamRole.thief;
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GamePlayScreen(
            role: _players.firstWhere((p) => p.id == '1').role,
            gameName: widget.gameName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 참가자가 준비를 완료해야 합니다')));
    }
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('방 나가기'),
        content: const Text('정말 방을 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.gameName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _showLeaveDialog,
        ),
        actions: [
          IconButton(
            onPressed: () {
              // settings
            },
            icon: const Icon(Icons.settings, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                return _buildPlayerCard(_players[index]);
              },
            ),
          ),
          if (widget.isHost && widget.roleMethod == RoleAssignmentMethod.random)
            _buildRandomRoleSettings(),
          _buildBottomArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
          const Text(
            '입장 코드',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.roomCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('코드가 복사되었습니다!')));
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                tooltip: '코드 복사',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _showQRCodeDialog,
                icon: const Icon(Icons.qr_code_2, color: Colors.white),
                tooltip: 'QR 코드 보기',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '현재 인원 ${_players.length}/8명',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '방 입장 QR 코드',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: widget.roomCode,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                '코드: ${widget.roomCode}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Player player) {
    final isMe = player.id == '1';
    final isPolice = player.role == TeamRole.police;
    final roleColor = isPolice ? AppColors.police : AppColors.thief;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: roleColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: roleColor, size: 28),
                ),
                if (player.isHost)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        player.nickname,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                            '나',
                            style: TextStyle(color: Colors.white, fontSize: 10),
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
                          '준비완료',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      '대기중...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (_canModifyRole(player, isMe))
              _buildRoleToggle(player)
            else
              _buildRoleDisplay(player),
            if (widget.isHost && !isMe)
              IconButton(
                onPressed: () => _kickPlayer(player),
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.danger,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canModifyRole(Player player, bool isMe) {
    if (widget.roleMethod == RoleAssignmentMethod.random) return false;
    if (widget.roleMethod == RoleAssignmentMethod.manual && isMe) return true;
    if (widget.roleMethod == RoleAssignmentMethod.host && widget.isHost) {
      return true;
    }
    return false;
  }

  Widget _buildRoleToggle(Player player) {
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
            onTap: () => setState(() => player.role = TeamRole.police),
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
                  color: isPolice ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => player.role = TeamRole.thief),
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
                  color: !isPolice ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDisplay(Player player) {
    if (widget.roleMethod == RoleAssignmentMethod.random) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '❓ 미정',
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
        player.role == TeamRole.police ? '👮 경찰' : '🏃 도둑',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: player.role == TeamRole.police
              ? AppColors.police
              : AppColors.thief,
        ),
      ),
    );
  }

  Widget _buildRandomRoleSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🕵️ 경찰 인원 설정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$_policeCount명',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _policeCount.toDouble(),
            min: 1,
            max: math.max(1, _players.length - 1).toDouble(),
            divisions: math.max(1, _players.length - 2),
            label: '$_policeCount명',
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _policeCount = value.toInt();
              });
            },
          ),
          const Text(
            '게임 시작 시 무작위로 경찰이 배정됩니다.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Chat Preview Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(title: '전체 채팅', isTeamChat: false),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '플레이어2: 준비됐어요!',
                      style: TextStyle(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Ready/Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isHost ? _startGame : _toggleReady,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isHost
                    ? AppColors.success
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor:
                    (widget.isHost ? AppColors.success : AppColors.primary)
                        .withOpacity(0.5),
              ),
              child: Text(
                widget.isHost ? '게임 시작' : (_isReady ? '준비 취소' : '준비 완료'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _kickPlayer(Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('강퇴'),
        content: Text('${player.nickname}님을 강퇴하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _players.removeWhere((p) => p.id == player.id);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('강퇴'),
          ),
        ],
      ),
    );
  }
}
