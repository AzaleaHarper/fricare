import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FrictionMath extends StatefulWidget {
  final int totalProblems;
  final VoidCallback onComplete;

  const FrictionMath({
    super.key,
    this.totalProblems = 3,
    required this.onComplete,
  });

  @override
  State<FrictionMath> createState() => _FrictionMathState();
}

class _FrictionMathState extends State<FrictionMath> {
  final _rng = Random();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  int _currentProblem = 0;
  late int _a;
  late int _b;
  late bool _isAddition;
  late int _answer;

  /// null = neutral, true = correct flash, false = wrong flash
  bool? _flash;

  @override
  void initState() {
    super.initState();
    _generateProblem();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _generateProblem() {
    _isAddition = _rng.nextBool();
    if (_isAddition) {
      _a = 10 + _rng.nextInt(90); // 10-99
      _b = 1 + _rng.nextInt(49); // 1-49
      _answer = _a + _b;
    } else {
      // Ensure positive result: a > b
      _a = 11 + _rng.nextInt(89); // 11-99
      _b = 1 + _rng.nextInt(_a - 1).clamp(1, 49); // 1-49, < a
      _answer = _a - _b;
    }
  }

  void _submit() {
    final input = int.tryParse(_controller.text.trim());
    if (input == null) return;

    if (input == _answer) {
      _showFlash(true);
      _currentProblem++;
      if (_currentProblem >= widget.totalProblems) {
        widget.onComplete();
        return;
      }
      _generateProblem();
      _controller.clear();
      _focusNode.requestFocus();
    } else {
      _showFlash(false);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  void _showFlash(bool correct) {
    setState(() => _flash = correct);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final op = _isAddition ? '+' : '-';

    final borderColor = switch (_flash) {
      true => theme.colorScheme.primary,
      false => theme.colorScheme.error,
      null => Colors.transparent,
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.calculate_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Solve to continue',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Problem ${_currentProblem + 1} of ${widget.totalProblems}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.totalProblems, (i) {
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    i < _currentProblem
                        ? theme.colorScheme.primary
                        : i == _currentProblem
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withAlpha(61),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        // Math problem display
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Text(
            '$_a $op $_b = ?',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Answer input
        SizedBox(
          width: 160,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: '???',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(77),
              ),
              filled: true,
              fillColor: theme.colorScheme.onSurface.withAlpha(26),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _submit, child: const Text('Submit')),
      ],
    );
  }
}
