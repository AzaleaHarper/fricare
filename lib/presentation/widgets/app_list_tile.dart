import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/models/friction_type.dart';

class AppListTile extends StatelessWidget {
  final String appName;
  final String packageName;
  final Uint8List? icon;
  final bool isSelected;
  final bool? frictionEnabled;
  final FrictionKind? frictionKind;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;

  const AppListTile({
    super.key,
    required this.appName,
    required this.packageName,
    this.icon,
    required this.isSelected,
    this.frictionEnabled,
    this.frictionKind,
    required this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = isSelected && frictionEnabled == false;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) => onToggle(value ?? false),
          ),
          _AppIcon(icon: icon, size: 32),
        ],
      ),
      title: Text(
        appName,
        style: isDisabled ? TextStyle(color: theme.disabledColor) : null,
      ),
      trailing:
          isSelected && frictionKind != null
              ? Chip(
                label: Text(
                  _kindLabel(frictionKind!),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDisabled ? theme.disabledColor : null,
                  ),
                ),
                avatar:
                    isDisabled
                        ? Icon(
                          Icons.pause_circle_outline,
                          size: 12,
                          color: theme.disabledColor,
                        )
                        : null,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              )
              : null,
      onTap: onTap,
    );
  }

  String _kindLabel(FrictionKind kind) => switch (kind) {
    FrictionKind.holdToOpen => 'Hold',
    FrictionKind.puzzle => 'Puzzle',
    FrictionKind.confirmation => 'Confirm',
    FrictionKind.math => 'Math',
    FrictionKind.none => 'None',
  };
}

class _AppIcon extends StatelessWidget {
  final Uint8List? icon;
  final double size;
  const _AppIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    if (icon != null && icon!.isNotEmpty) {
      return Image.memory(icon!, width: size, height: size);
    }
    return Icon(
      Icons.android,
      size: size,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}
