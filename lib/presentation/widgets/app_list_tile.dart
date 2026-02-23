import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/models/friction_type.dart';

class AppListTile extends StatelessWidget {
  final String appName;
  final String packageName;
  final Uint8List? icon;
  final bool isManaged;
  final FrictionKind? frictionKind;
  final VoidCallback onTap;

  const AppListTile({
    super.key,
    required this.appName,
    required this.packageName,
    this.icon,
    required this.isManaged,
    this.frictionKind,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: _AppIcon(icon: icon, size: 36),
      title: Text(appName),
      trailing:
          isManaged
              ? Chip(
                avatar: Icon(
                  Icons.check,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  frictionKind != null ? _kindLabel(frictionKind!) : 'Added',
                  style: const TextStyle(fontSize: 11),
                ),
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
