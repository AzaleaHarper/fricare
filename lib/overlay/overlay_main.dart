import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models/friction_type.dart';
import '../presentation/theme/app_theme.dart';
import '../presentation/widgets/friction_confirmation.dart';
import '../presentation/widgets/friction_hold_button.dart';
import '../presentation/widgets/friction_math.dart';
import '../presentation/widgets/friction_puzzle.dart';

/// Dynamic theme notifier — updated each time showFriction is pushed.
final _themeNotifier = ValueNotifier<ThemeData>(
  buildAppTheme(accentColorIndex: 0, brightness: Brightness.dark),
);

/// Separate entry point for the overlay engine.
/// Pre-warmed by AppLaunchDetectorService; receives config via push.
@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    ValueListenableBuilder<ThemeData>(
      valueListenable: _themeNotifier,
      builder:
          (_, theme, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: child,
          ),
      child: const OverlayScreen(),
    ),
  );
}

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  static const _channel = MethodChannel('com.fricare/overlay');

  FrictionKind _kind = FrictionKind.holdToOpen;
  int _delaySeconds = 3;
  int _puzzleTaps = 5;
  int _confirmationSteps = 2;
  int _mathProblems = 3;
  String _appName = '';
  bool _loaded = false;

  // Chain state
  List<ChainStep> _chainSteps = [];
  int _chainIndex = 0;
  bool _isChainMode = false;

  // Incremented on each config push to force child widget rebuild
  int _configVersion = 0;

  @override
  void initState() {
    super.initState();
    // Listen for config pushes from the Kotlin service
    _channel.setMethodCallHandler(_handlePlatformCall);
  }

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    if (call.method == 'showFriction') {
      final config = Map<String, dynamic>.from(call.arguments as Map);
      final chainJson = config['chainStepsJson'] as String? ?? '[]';
      final chainList =
          (jsonDecode(chainJson) as List)
              .map((e) => ChainStep.fromJson(e as Map<String, dynamic>))
              .toList();

      // Update overlay theme from pushed config
      final accentColorIndex = config['accentColorIndex'] as int? ?? 0;
      final amoledDark = config['amoledDark'] as bool? ?? false;
      _themeNotifier.value = buildAppTheme(
        accentColorIndex: accentColorIndex,
        brightness: Brightness.dark,
        amoledDark: amoledDark,
      );

      setState(() {
        _configVersion++;
        _appName = config['appName'] as String;
        _puzzleTaps = config['puzzleTaps'] as int? ?? 5;
        _mathProblems = config['mathProblems'] as int? ?? 3;
        _confirmationSteps = config['confirmationSteps'] as int;
        _delaySeconds = config['delaySeconds'] as int;

        if (chainList.isNotEmpty) {
          _chainSteps = chainList;
          _chainIndex = 0;
          _isChainMode = true;
          _applyChainStep(chainList[0]);
        } else {
          _kind = FrictionKind.values[config['kind'] as int];
          _chainSteps = [];
          _chainIndex = 0;
          _isChainMode = false;
        }
        _loaded = true;
      });
    }
  }

  void _applyChainStep(ChainStep step) {
    _kind = step.kind;
    _delaySeconds = step.delaySeconds;
    _puzzleTaps = step.puzzleTaps;
    _confirmationSteps = step.confirmationSteps;
    _mathProblems = step.mathProblems;
  }

  Future<void> _onStepComplete() async {
    if (!_isChainMode) {
      await _onFrictionComplete();
      return;
    }
    _chainIndex++;
    if (_chainIndex >= _chainSteps.length) {
      await _onFrictionComplete();
      return;
    }
    setState(() {
      _applyChainStep(_chainSteps[_chainIndex]);
    });
  }

  Future<void> _onFrictionComplete() async {
    await _channel.invokeMethod('frictionComplete');
    if (mounted) {
      setState(() {
        _loaded = false;
        _chainIndex = 0;
        _isChainMode = false;
      });
    }
  }

  Future<void> _onCancel() async {
    await _channel.invokeMethod('frictionCancelled');
    if (mounted) {
      setState(() {
        _loaded = false;
        _chainIndex = 0;
        _isChainMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      // Invisible until config is pushed — no loading spinner flash
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: _onCancel,
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ),
              // Chain progress indicator
              if (_isChainMode) ...[
                Text(
                  'Step ${_chainIndex + 1} of ${_chainSteps.length}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_chainSteps.length, (i) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            i < _chainIndex
                                ? theme.colorScheme.primary
                                : i == _chainIndex
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withAlpha(61),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                key: ValueKey('config_${_configVersion}_$_chainIndex'),
                child: _buildFriction(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriction() {
    switch (_kind) {
      case FrictionKind.holdToOpen:
        return FrictionHoldButton(
          holdDurationSeconds: _delaySeconds,
          onComplete: _onStepComplete,
        );
      case FrictionKind.puzzle:
        return FrictionPuzzle(
          targetTaps: _puzzleTaps,
          onComplete: _onStepComplete,
        );
      case FrictionKind.confirmation:
        return FrictionConfirmation(
          totalSteps: _confirmationSteps,
          appName: _appName,
          onComplete: _onStepComplete,
          onCancel: _onCancel,
        );
      case FrictionKind.math:
        return FrictionMath(
          totalProblems: _mathProblems,
          onComplete: _onStepComplete,
        );
      case FrictionKind.none:
        Future.microtask(_onStepComplete);
        return const SizedBox.shrink();
    }
  }
}
