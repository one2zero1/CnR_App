import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import 'waiting_room_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String get _roomCode => _codeController.text;
  bool get _isCodeComplete => _roomCode.length == 6;

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _joinRoom() async {
    if (_isCodeComplete) {
      setState(() => _isLoading = true);
      try {
        final authService = context.read<AuthService>();
        final roomService = context.read<RoomService>();

        var user = authService.currentUser;
        if (user == null) {
          user = await authService.signInAnonymously(
            'Guest_${DateTime.now().second}',
          );
        }

        final roomId = await roomService.joinRoom(
          pinCode: _roomCode,
          user: user,
        );

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomScreen(
              roomId: roomId,
              roomCode: _roomCode,
              isHost: false,
              gameName: '참가한 방',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('방 참가 실패: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanQR() async {
    final String? code = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('QR 코드 스캔')),
          body: MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              formats: [BarcodeFormat.qrCode],
            ),
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );

    if (code != null) {
      final cleanCode = code.trim();
      if (cleanCode.length == 6) {
        _codeController.text = cleanCode;
        setState(() {});
        _joinRoom();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('유효하지 않은 QR 코드입니다: $cleanCode')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            const Icon(Icons.vpn_key, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              '방 코드 입력',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface, // Adaptive value
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '6자리 방 코드를 입력하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color, // Adaptive value
              ),
            ),
            const SizedBox(height: 48),

            // Hidden TextField + Visible Boxes Pattern
            Stack(
              alignment: Alignment.center,
              children: [
                // Hidden TextField to capture input
                Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _codeController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    onChanged: (value) {
                      setState(() {});
                      if (value.length == 6) {
                        // Optional: Auto-submit or just dismiss keyboard
                      }
                    },
                  ),
                ),
                // Visible Boxes
                GestureDetector(
                  onTap: () => FocusScope.of(context).requestFocus(_focusNode),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      String char = '';
                      if (index < _codeController.text.length) {
                        char = _codeController.text[index];
                      }
                      bool isFocused = index == _codeController.text.length;
                      if (_codeController.text.length == 6 && index == 5)
                        isFocused = true; // Keep last focused if full

                      return Container(
                        width: 48,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: char.isNotEmpty
                              ? AppColors.primary.withOpacity(0.1)
                              : theme.inputDecorationTheme.fillColor ??
                                    Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFocused && _focusNode.hasFocus
                                ? AppColors.primary
                                : (char.isNotEmpty
                                      ? AppColors.primary
                                      : theme.disabledColor),
                            width: isFocused && _focusNode.hasFocus ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          char,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isCodeComplete ? _joinRoom : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: theme.disabledColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('참가하기', style: TextStyle(fontSize: 18)),
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
