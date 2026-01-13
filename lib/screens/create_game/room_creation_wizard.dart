import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/game_types.dart';
import 'package:latlong2/latlong.dart';
import 'steps/step_1_name.dart';
import 'steps/step_2_time.dart';
import 'steps/step_3_interval.dart';
import 'steps/step_4_roles.dart';
import 'steps/step_5_area.dart';
import 'steps/step_6_jail.dart';

class RoomCreationWizard extends StatefulWidget {
  const RoomCreationWizard({super.key});

  @override
  State<RoomCreationWizard> createState() => _RoomCreationWizardState();
}

class _RoomCreationWizardState extends State<RoomCreationWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Game Settings State
  String _gameName = '';
  double _playTime = 30; // minutes
  double _locationInterval = 3; // minutes
  RoleAssignmentMethod _roleMethod = RoleAssignmentMethod.manual;
  double _areaRadius = 300; // meters
  LatLng _centerPosition = const LatLng(37.5665, 126.9780); // Default Seoul
  LatLng? _jailPosition;
  bool _isStep5Loading =
      true; // Default to true as it starts loading immediately

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus(); // Dismiss keyboard

    if (_currentStep == 4 && _isStep5Loading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치를 불러오는 중입니다. 잠시만 기다려주세요.')),
      );
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _onStepChanged(int index) {
    setState(() {
      _currentStep = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '새 게임 만들기 (${_currentStep + 1}/$_totalSteps)',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: _prevStep,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppColors.textHint.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: _onStepChanged,
                children: [
                  Step1Name(
                    initialName: _gameName,
                    onNameChanged: (value) => setState(() => _gameName = value),
                  ),
                  Step2Time(
                    initialTime: _playTime,
                    onTimeChanged: (value) => setState(() => _playTime = value),
                  ),
                  Step3Interval(
                    initialInterval: _locationInterval,
                    onIntervalChanged: (value) =>
                        setState(() => _locationInterval = value),
                  ),
                  Step4Roles(
                    initialMethod: _roleMethod,
                    onMethodChanged: (value) =>
                        setState(() => _roleMethod = value),
                  ),
                  Step5Area(
                    initialCenter: _centerPosition,
                    initialRadius: _areaRadius,
                    onAreaChanged: (center, radius) {
                      setState(() {
                        _centerPosition = center;
                        _areaRadius = radius;
                      });
                    },
                    onLoadingStateChanged: (isLoading) {
                      // Prevent setState if widget is unmounted or no change
                      if (_isStep5Loading != isLoading) {
                        // Using addPostFrameCallback to avoid build phase errors if called immediately
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _isStep5Loading = isLoading);
                          }
                        });
                      }
                    },
                  ),
                  Step6Jail(
                    gameName: _gameName.isEmpty ? '새 게임' : _gameName,
                    playTime: _playTime.toInt(),
                    locationInterval: _locationInterval.toInt(),
                    roleMethod: _roleMethod,
                    centerPosition: _centerPosition,
                    radius: _areaRadius.toInt(),
                    initialJailPosition: _jailPosition,
                    onJailSelected: (pos) =>
                        setState(() => _jailPosition = pos),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.textHint),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '이전',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (_currentStep < _totalSteps - 1)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: (_currentStep == 4 && _isStep5Loading)
                            ? null
                            : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              Colors.grey[300], // Explicit disabled color
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _currentStep == 4 && _isStep5Loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '다음',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
