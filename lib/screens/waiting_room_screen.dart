import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'game_play_screen.dart';
import 'chat_screen.dart';

enum PlayerRole { police, thief }

class Player {
  final String id;
  final String nickname;
  PlayerRole role;
  bool isReady;
  bool isHost;

  Player({
    required this.id,
    required this.nickname,
    this.role = PlayerRole.thief,
    this.isReady = false,
    this.isHost = false,
  });
}

class WaitingRoomScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final String gameName;

  const WaitingRoomScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
    required this.gameName,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  late List<Player> _players;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _players = [
      Player(id: '1', nickname: '나', role: PlayerRole.police, isHost: widget.isHost, isReady: true),
      Player(id: '2', nickname: '플레이어2', role: PlayerRole.thief, isReady: true),
      Player(id: '3', nickname: '플레이어3', role: PlayerRole.thief, isReady: false),
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GamePlayScreen(
            role: _players.first.role,
            gameName: widget.gameName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 참가자가 준비를 완료해야 합니다')),
      );
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
      appBar: AppBar(
        title: Text(widget.gameName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showLeaveDialog,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 18),
                const SizedBox(width: 4),
                Text('${_players.length}/8'),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.vpn_key, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '방 코드: ${widget.roomCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                return _buildPlayerCard(_players[index]);
              },
            ),
          ),
          _buildChatPreview(),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Player player) {
    final isMe = player.id == '1';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: player.role == PlayerRole.police
                      ? AppColors.police.withOpacity(0.2)
                      : AppColors.thief.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: player.role == PlayerRole.police
                        ? AppColors.police
                        : AppColors.thief,
                  ),
                ),
                if (player.isHost)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, size: 12, color: Colors.white),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                        Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          '준비완료',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
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
            if (isMe || widget.isHost)
              _buildRoleToggle(player)
            else
              _buildRoleDisplay(player),
            if (widget.isHost && !isMe)
              IconButton(
                onPressed: () => _kickPlayer(player),
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleToggle(Player player) {
    return SegmentedButton<PlayerRole>(
      segments: const [
        ButtonSegment(
          value: PlayerRole.police,
          label: Text('👮', style: TextStyle(fontSize: 16)),
        ),
        ButtonSegment(
          value: PlayerRole.thief,
          label: Text('🏃', style: TextStyle(fontSize: 16)),
        ),
      ],
      selected: {player.role},
      onSelectionChanged: (roles) {
        setState(() {
          player.role = roles.first;
        });
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildRoleDisplay(Player player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: player.role == PlayerRole.police
            ? AppColors.police.withOpacity(0.1)
            : AppColors.thief.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        player.role == PlayerRole.police ? '👮 경찰' : '🏃 도둑',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: player.role == PlayerRole.police
              ? AppColors.police
              : AppColors.thief,
        ),
      ),
    );
  }

  Widget _buildChatPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Text(
            '플레이어2: 준비됐어요!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    title: '전체 채팅',
                    isTeamChat: false,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(width: 8),
          if (widget.isHost)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: widget.isHost
                ? ElevatedButton.icon(
                    onPressed: _startGame,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('게임 시작'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _toggleReady,
                    icon: Icon(_isReady ? Icons.close : Icons.check),
                    label: Text(_isReady ? '준비 취소' : '준비 완료'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isReady ? Colors.grey : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
