import 'package:flutter/material.dart';

class FrictionHoldButton extends StatefulWidget {
  final int holdDurationSeconds;
  final VoidCallback onComplete;

  const FrictionHoldButton({
    super.key,
    required this.holdDurationSeconds,
    required this.onComplete,
  });

  @override
  State<FrictionHoldButton> createState() => _FrictionHoldButtonState();
}

class _FrictionHoldButtonState extends State<FrictionHoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.holdDurationSeconds),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown() {
    setState(() => _holding = true);
    _controller.forward();
  }

  void _onPointerUp() {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reset();
    }
    setState(() => _holding = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hold to Open',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Hold the button for ${widget.holdDurationSeconds} seconds',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onLongPressStart: (_) => _onPointerDown(),
          onLongPressEnd: (_) => _onPointerUp(),
          onLongPressCancel: () => _onPointerUp(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _controller.value,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _holding
                            ? theme.colorScheme.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                    Icon(
                      _controller.isCompleted
                          ? Icons.check_circle
                          : Icons.touch_app,
                      size: 64,
                      color: _holding
                          ? theme.colorScheme.primary
                          : Colors.grey.shade400,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final remaining =
                (widget.holdDurationSeconds * (1 - _controller.value)).ceil();
            return Text(
              _holding ? '$remaining s remaining' : 'Press and hold',
              style: theme.textTheme.bodyLarge,
            );
          },
        ),
      ],
    );
  }
}
