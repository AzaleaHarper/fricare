import 'package:flutter/material.dart';

import '../../domain/models/friction_type.dart';
import '../widgets/friction_confirmation.dart';
import '../widgets/friction_hold_button.dart';
import '../widgets/friction_math.dart';
import '../widgets/friction_puzzle.dart';

class TestFrictionScreen extends StatefulWidget {
  final FrictionConfig frictionConfig;
  final String appName;

  const TestFrictionScreen({
    super.key,
    required this.frictionConfig,
    required this.appName,
  });

  @override
  State<TestFrictionScreen> createState() => _TestFrictionScreenState();
}

class _TestFrictionScreenState extends State<TestFrictionScreen> {
  late final bool _isChainMode;
  late final List<ChainStep> _chainSteps;
  int _chainIndex = 0;

  // Current step parameters (mutated during chain progression)
  late FrictionKind _kind;
  late int _delaySeconds;
  late int _puzzleTaps;
  late int _confirmationSteps;
  late int _mathProblems;

  @override
  void initState() {
    super.initState();
    final config = widget.frictionConfig;
    _chainSteps = config.chainSteps;
    _isChainMode = _chainSteps.isNotEmpty;

    if (_isChainMode) {
      _applyChainStep(_chainSteps[0]);
    } else {
      _kind = config.kind;
      _delaySeconds = config.effectiveDelay;
      _puzzleTaps = config.puzzleTaps;
      _confirmationSteps = config.confirmationSteps;
      _mathProblems = config.mathProblems;
    }
  }

  void _applyChainStep(ChainStep step) {
    _kind = step.kind;
    _delaySeconds = step.delaySeconds;
    _puzzleTaps = step.puzzleTaps;
    _confirmationSteps = step.confirmationSteps;
    _mathProblems = step.mathProblems;
  }

  void _onStepComplete() {
    if (!_isChainMode) {
      _showSuccess();
      return;
    }
    final nextIndex = _chainIndex + 1;
    if (nextIndex >= _chainSteps.length) {
      _showSuccess();
      return;
    }
    setState(() {
      _chainIndex = nextIndex;
      _applyChainStep(_chainSteps[nextIndex]);
    });
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Friction completed! App would launch now.'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Friction')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isChainMode) ...[
              Text(
                'Step ${_chainIndex + 1} of ${_chainSteps.length}',
                style: Theme.of(context).textTheme.bodySmall,
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
                              ? Theme.of(context).colorScheme.primary
                              : i == _chainIndex
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              key: ValueKey('test_chain_$_chainIndex'),
              child: _buildFrictionWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrictionWidget() {
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
          appName: widget.appName,
          onComplete: _onStepComplete,
          onCancel: () => Navigator.pop(context),
        );
      case FrictionKind.math:
        return FrictionMath(
          totalProblems: _mathProblems,
          onComplete: _onStepComplete,
        );
      case FrictionKind.none:
        return const Center(
          child: Text('No friction configured for this tier.'),
        );
    }
  }
}
