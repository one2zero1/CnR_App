import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/game_types.dart';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final TeamRole userRole;
  final String title;
  final bool isTeamChat;
  final bool enableTeamChat;
  final Color? themeColor;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.userRole,
    required this.title,
    this.isTeamChat = false,
    this.enableTeamChat = true,
    this.themeColor,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Tab controller for filtering View (Global vs Team)
  late TabController _tabController;
  // Current intended send target (defaults based on Tab or isTeamChat)
  ChatType _currentType = ChatType.global;

  @override
  void initState() {
    super.initState();
    // 2 Tabs: Global, Team (if enabled)
    _tabController = TabController(
      length: widget.enableTeamChat ? 2 : 1,
      vsync: this,
    );

    // Default tab based on isTeamChat
    if (widget.isTeamChat) {
      _tabController.index = 1; // Team tab
      _currentType = ChatType.team;
    }

    if (widget.enableTeamChat) {
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {
            _currentType = _tabController.index == 1
                ? ChatType.team
                : ChatType.global;
          });
        }
      });
    } else {
      _currentType = ChatType.global;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authService = context.read<AuthService>();
    final chatService = context.read<ChatService>();
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    try {
      await chatService.sendMessage(
        roomId: widget.roomId,
        uid: user.uid,
        nickname: user.nickname,
        message: text,
        type: _currentType,
        team: widget
            .userRole, // Always pass my role, service stores it if type is team
      );

      _messageController.clear();
      // Scroll to bottom is handled by StreamBuilder's reverse list or manual scroll
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('메시지 전송 실패: $e')));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0.0, // Using reverse: true in ListView, so 0 is bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.themeColor ?? AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: widget.enableTeamChat
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white, // Selected text color
                unselectedLabelColor: Colors.white70, // Unselected text color
                tabs: const [
                  Tab(text: '전체 채팅'),
                  Tab(text: '팀 채팅'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: context.read<ChatService>().getMessagesStream(
                widget.roomId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allMessages = snapshot.data!;

                if (widget.enableTeamChat) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMessageList(
                        allMessages,
                        ChatType.global,
                        primaryColor,
                      ),
                      _buildMessageList(
                        allMessages,
                        ChatType.team,
                        primaryColor,
                      ),
                    ],
                  );
                } else {
                  return _buildMessageList(
                    allMessages,
                    ChatType.global,
                    primaryColor,
                  );
                }
              },
            ),
          ),
          _buildInputArea(primaryColor),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    List<ChatMessage> allMessages,
    ChatType type,
    Color primaryColor,
  ) {
    // Filter messages based on type
    final filteredMessages = allMessages.where((msg) {
      if (type == ChatType.global) {
        return msg.type == ChatType.global;
      } else {
        // Team Tab: Show team messages for MY team
        return msg.type == ChatType.team && msg.team == widget.userRole;
      }
    }).toList();

    // Reverse for ListView
    final reversedMessages = filteredMessages.reversed.toList();

    return ListView.builder(
      controller: type == _currentType ? _scrollController : null,
      reverse: true, // Start from bottom
      padding: const EdgeInsets.all(16),
      itemCount: reversedMessages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(reversedMessages[index], primaryColor);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Color primaryColor) {
    final authService = context.read<AuthService>();
    final isMe = message.senderId == authService.currentUser?.uid;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.type == ChatType.team)
                      Icon(
                        Icons.security,
                        size: 12,
                        color: primaryColor,
                      ), // Team Icon
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? primaryColor : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(Color primaryColor) {
    final theme = Theme.of(context);
    final isTeamMode = _currentType == ChatType.team;

    // Tint color for Team Chat mode
    final backgroundColor = isTeamMode
        ? primaryColor.withOpacity(0.05)
        : theme.scaffoldBackgroundColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: isTeamMode ? '팀원에게 메시지 입력...' : '전체에게 메시지 입력...',
                  filled: true,
                  fillColor: isTeamMode
                      ? primaryColor.withOpacity(0.1)
                      : theme.inputDecorationTheme.fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              color: primaryColor,
              style: IconButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
