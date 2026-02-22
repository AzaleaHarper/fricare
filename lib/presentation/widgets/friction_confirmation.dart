import 'package:flutter/material.dart';

class FrictionConfirmation extends StatefulWidget {
  final int totalSteps;
  final String appName;
  final VoidCallback onComplete;
  final VoidCallback? onCancel;

  const FrictionConfirmation({
    super.key,
    required this.totalSteps,
    required this.appName,
    required this.onComplete,
    this.onCancel,
  });

  @override
  State<FrictionConfirmation> createState() => _FrictionConfirmationState();
}

class _FrictionConfirmationState extends State<FrictionConfirmation> {
  int _currentStep = 0;

  static const _prompts = [
    'Do you really want to open this app?',
    'Are you sure? Think about it.',
    'Last chance. Still want to continue?',
  ];

  void _confirm() {
    if (_currentStep + 1 >= widget.totalSteps) {
      widget.onComplete();
    } else {
      setState(() => _currentStep++);
    }
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promptIndex = _currentStep.clamp(0, _prompts.length - 1);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 64,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(height: 24),
        Text(
          _prompts[promptIndex],
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Opening ${widget.appName}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Step ${_currentStep + 1} of ${widget.totalSteps}',
          style: theme.textTheme.bodySmall,
        ),
        // Step indicator dots
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.totalSteps, (i) {
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    i <= _currentStep
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(onPressed: _cancel, child: const Text('Go Back')),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: _confirm,
              child: Text(
                _currentStep + 1 >= widget.totalSteps ? 'Open App' : 'Continue',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
