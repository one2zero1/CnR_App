import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class Step1Name extends StatelessWidget {
  final String initialName;
  final ValueChanged<String> onNameChanged;

  const Step1Name({
    super.key,
    required this.initialName,
    required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.games,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '게임 이름 설정',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '친구들이 알아볼 수 있는 방 이름을 입력하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: TextEditingController(text: initialName)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: initialName.length),
                  ), // Set cursor to end
                onChanged: onNameChanged,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  hintText: '예: 즐거운 술래잡기',
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
