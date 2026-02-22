import 'package:flutter/material.dart';

import '../../domain/models/friction_type.dart';
import '../widgets/friction_confirmation.dart';
import '../widgets/friction_hold_button.dart';
import '../widgets/friction_math.dart';
import '../widgets/friction_puzzle.dart';

class TestFrictionScreen extends StatelessWidget {
  final FrictionConfig frictionConfig;
  final String appName;

  const TestFrictionScreen({
    super.key,
    required this.frictionConfig,
    required this.appName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Friction')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildFrictionWidget(context),
      ),
    );
  }

  Widget _buildFrictionWidget(BuildContext context) {
    switch (frictionConfig.kind) {
      case FrictionKind.holdToOpen:
        return FrictionHoldButton(
          holdDurationSeconds: frictionConfig.effectiveDelay,
          onComplete: () => _showSuccess(context),
        );
      case FrictionKind.puzzle:
        return FrictionPuzzle(
          targetTaps: frictionConfig.puzzleTaps,
          onComplete: () => _showSuccess(context),
        );
      case FrictionKind.confirmation:
        return FrictionConfirmation(
          totalSteps: frictionConfig.confirmationSteps,
          appName: appName,
          onComplete: () => _showSuccess(context),
        );
      case FrictionKind.math:
        return FrictionMath(
          totalProblems: frictionConfig.mathProblems,
          onComplete: () => _showSuccess(context),
        );
      case FrictionKind.none:
        return const Center(child: Text('No friction configured for this tier.'));
    }
  }

  void _showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friction completed! App would launch now.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}
