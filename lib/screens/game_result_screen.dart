import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'route_replay_screen.dart';

class GameResultScreen extends StatefulWidget {
  final String gameName;

  const GameResultScreen({super.key, required this.gameName});

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  int _selectedTab = 0;

  final List<PlayerResult> _results = [
    PlayerResult(
      rank: 1,
      nickname: '경찰1',
      role: '경찰',
      isPolice: true,
      stat: '3명 포획',
      isMvp: true,
    ),
    PlayerResult(
      rank: 2,
      nickname: '도둑1',
      role: '도둑',
      isPolice: false,
      stat: '25분 생존',
    ),
    PlayerResult(
      rank: 3,
      nickname: '경찰2',
      role: '경찰',
      isPolice: true,
      stat: '1명 포획',
    ),
    PlayerResult(
      rank: 4,
      nickname: '나',
      role: '도둑',
      isPolice: false,
      stat: '12분 생존',
      isMe: true,
    ),
  ];

  List<PlayerResult> get _filteredResults {
    if (_selectedTab == 0) return _results;
    if (_selectedTab == 1) return _results.where((r) => r.isPolice).toList();
    return _results.where((r) => !r.isPolice).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMvpCard(),
            _buildTabBar(),
            Expanded(child: _buildResultsList()),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.police, AppColors.police.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 60),
          SizedBox(height: 16),
          Text(
            '🎉 게임 종료',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '👮 경찰 승리!',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '모든 도둑 포획 - 소요시간: 25분 30초',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMvpCard() {
    final mvp = _results.firstWhere((r) => r.isMvp);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏆 MVP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  mvp.nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${mvp.role} · ${mvp.stat}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              mvp.isPolice ? Icons.local_police : Icons.directions_run,
              color: mvp.isPolice ? AppColors.police : AppColors.thief,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('전체', 0),
          _buildTab('경찰', 1),
          _buildTab('도둑', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        return _buildResultCard(_filteredResults[index]);
      },
    );
  }

  Widget _buildResultCard(PlayerResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: result.rank <= 3
                    ? [Colors.amber, Colors.grey.shade400, Colors.brown.shade300][result.rank - 1]
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${result.rank}',
                  style: TextStyle(
                    color: result.rank <= 3 ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: result.isPolice
                  ? AppColors.police.withOpacity(0.2)
                  : AppColors.thief.withOpacity(0.2),
              child: Icon(
                result.isPolice ? Icons.local_police : Icons.directions_run,
                color: result.isPolice ? AppColors.police : AppColors.thief,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        result.nickname,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (result.isMe)
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
                      if (result.isMvp)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MVP',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    result.role,
                    style: TextStyle(
                      color: result.isPolice ? AppColors.police : AppColors.thief,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              result.stat,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RouteReplayScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('경로 보기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  label: const Text('결과 공유'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat),
                  label: const Text('채팅'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 하기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(nickname: '플레이어'),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('홈으로'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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

class PlayerResult {
  final int rank;
  final String nickname;
  final String role;
  final bool isPolice;
  final String stat;
  final bool isMvp;
  final bool isMe;

  PlayerResult({
    required this.rank,
    required this.nickname,
    required this.role,
    required this.isPolice,
    required this.stat,
    this.isMvp = false,
    this.isMe = false,
  });
}
