import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_validateNickname);
  }

  void _validateNickname() {
    final nickname = _nicknameController.text;
    setState(() {
      _isValid = nickname.length >= 2 && nickname.length <= 8;
    });
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final nickname = _nicknameController.text;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(nickname: nickname)),
      );
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 32),
                const Text(
                  '닉네임 설정',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '게임에서 사용할 닉네임을 입력하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _nicknameController,
                  textAlign: TextAlign.center,
                  maxLength: 8,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    hintText: '닉네임 입력',
                    counterText: '${_nicknameController.text.length}/8',
                    prefixIcon: const Icon(Icons.edit),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    if (value.length < 2) {
                      return '닉네임은 2자 이상이어야 합니다';
                    }
                    if (value.length > 8) {
                      return '닉네임은 8자 이하여야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isValid ? _onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.textHint,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '2-8자 사이로 입력해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isValid ? AppColors.success : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
