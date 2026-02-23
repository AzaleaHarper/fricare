import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A slider with an inline editable text field for precise control.
///
/// The slider provides quick adjustment within [min]–[max], while the text
/// field allows any positive integer.
class ValueSlider extends StatefulWidget {
  final String label;
  final String suffix;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const ValueSlider({
    super.key,
    required this.label,
    this.suffix = 's',
    required this.value,
    this.min = 1,
    this.max = 30,
    required this.onChanged,
  });

  @override
  State<ValueSlider> createState() => _ValueSliderState();
}

class _ValueSliderState extends State<ValueSlider> {
  late TextEditingController _controller;
  bool _editing = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(ValueSlider old) {
    super.didUpdateWidget(old);
    if (!_editing && old.value != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _commitText();
      setState(() => _editing = false);
    }
  }

  void _commitText() {
    final parsed = int.tryParse(_controller.text);
    if (parsed != null && parsed >= widget.min) {
      widget.onChanged(parsed);
    } else {
      _controller.text = '${widget.value}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sliderVal = widget.value.toDouble().clamp(
      widget.min.toDouble(),
      widget.max.toDouble(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: sliderVal,
                min: widget.min.toDouble(),
                max: widget.max.toDouble(),
                divisions: widget.max - widget.min,
                onChanged: (v) => widget.onChanged(v.round()),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 56,
              height: 40,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  suffixText: widget.suffix,
                  suffixStyle: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTap: () => setState(() => _editing = true),
                onSubmitted: (_) => _commitText(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
