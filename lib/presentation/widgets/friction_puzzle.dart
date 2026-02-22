import 'dart:math';

import 'package:flutter/material.dart';

class FrictionPuzzle extends StatefulWidget {
  final int targetTaps;
  final VoidCallback onComplete;

  const FrictionPuzzle({
    super.key,
    this.targetTaps = 5,
    required this.onComplete,
  });

  @override
  State<FrictionPuzzle> createState() => _FrictionPuzzleState();
}

class _FrictionPuzzleState extends State<FrictionPuzzle> {
  late List<int> _sequence;
  int _currentIndex = 0;
  int? _wrongTap;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _generateSequence();
  }

  void _generateSequence() {
    _sequence = List.generate(widget.targetTaps, (_) => _random.nextInt(9));
    _currentIndex = 0;
    _wrongTap = null;
  }

  void _onTilePressed(int index) {
    if (_sequence[_currentIndex] == index) {
      setState(() {
        _wrongTap = null;
        _currentIndex++;
      });
      if (_currentIndex >= _sequence.length) {
        widget.onComplete();
      }
    } else {
      setState(() {
        _wrongTap = index;
        _currentIndex = 0;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _wrongTap = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextTarget =
        _currentIndex < _sequence.length ? _sequence[_currentIndex] : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Tap Sequence', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Tap the highlighted tiles in order ($_currentIndex/${_sequence.length})',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 240,
          height: 240,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final isTarget = index == nextTarget;
              final isWrong = index == _wrongTap;
              final isCompleted = _sequence
                  .sublist(0, _currentIndex)
                  .contains(index);

              Color tileColor;
              if (isWrong) {
                tileColor = theme.colorScheme.error;
              } else if (isTarget) {
                tileColor = theme.colorScheme.primary;
              } else if (isCompleted) {
                tileColor = theme.colorScheme.primaryContainer;
              } else {
                tileColor = theme.colorScheme.surfaceContainerHighest;
              }

              return GestureDetector(
                onTap: () => _onTilePressed(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child:
                        isTarget
                            ? Icon(
                              Icons.touch_app,
                              color: theme.colorScheme.onPrimary,
                            )
                            : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
