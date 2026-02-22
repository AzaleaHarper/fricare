import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models/friction_type.dart';
import '../presentation/widgets/friction_confirmation.dart';
import '../presentation/widgets/friction_hold_button.dart';
import '../presentation/widgets/friction_math.dart';
import '../presentation/widgets/friction_puzzle.dart';

/// Separate entry point for the overlay activity.
/// Launched by OverlayActivity with a dedicated Flutter engine.
@pragma('vm:entry-point')
void overlayMain() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: const OverlayScreen(),
  ));
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
  bool _error = false;

  // Chain state
  List<ChainStep> _chainSteps = [];
  int _chainIndex = 0;
  bool _isChainMode = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _error = false);
    try {
      final config = await _channel
          .invokeMapMethod<String, dynamic>('getFrictionConfig')
          .timeout(const Duration(seconds: 5));
      if (config != null && mounted) {
        final chainJson = config['chainStepsJson'] as String? ?? '[]';
        final chainList = (jsonDecode(chainJson) as List)
            .map((e) => ChainStep.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
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
          }
          _loaded = true;
        });
      } else if (mounted) {
        setState(() => _error = true);
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
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
  }

  Future<void> _onCancel() async {
    await _channel.invokeMethod('frictionCancelled');
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: _error
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white70, size: 48),
                    const SizedBox(height: 16),
                    const Text('Failed to load friction',
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loadConfig,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _onCancel,
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: _onCancel,
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ),
              // Chain progress indicator
              if (_isChainMode) ...[
                Text(
                  'Step ${_chainIndex + 1} of ${_chainSteps.length}',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      List.generate(_chainSteps.length, (i) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _chainIndex
                            ? Colors.green
                            : i == _chainIndex
                                ? Colors.white
                                : Colors.white24,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                key: ValueKey('chain_$_chainIndex'),
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
