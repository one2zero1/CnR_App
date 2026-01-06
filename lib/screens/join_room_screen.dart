import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'waiting_room_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());

  String get _roomCode =>
      _digitControllers.map((c) => c.text).join();

  bool get _isCodeComplete => _roomCode.length == 6;

  @override
  void dispose() {
    _codeController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyPressed(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _digitControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _joinRoom() {
    if (_isCodeComplete) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(
            roomCode: _roomCode,
            isHost: false,
            gameName: '게임 방',
          ),
        ),
      );
    }
  }

  void _scanQR() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR 스캐너 기능은 추후 구현 예정입니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 참가하기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(
              Icons.vpn_key,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              '방 코드 입력',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '6자리 방 코드를 입력하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) => _onKeyPressed(index, event),
                    child: TextField(
                      controller: _digitControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: _digitControllers[index].text.isNotEmpty
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _digitControllers[index].text.isNotEmpty
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onDigitChanged(index, value),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isCodeComplete ? _joinRoom : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textHint,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '참가하기',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _scanQR,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QR 스캔'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
