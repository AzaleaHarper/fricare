import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/friction_type.dart';
import '../../infrastructure/platform/method_channels.dart';
import '../providers/friction_apps_provider.dart';
import '../providers/settings_provider.dart';
import 'app_config_screen.dart';

class ManagedAppsTab extends ConsumerStatefulWidget {
  const ManagedAppsTab({super.key});

  @override
  ConsumerState<ManagedAppsTab> createState() => _ManagedAppsTabState();
}

class _ManagedAppsTabState extends ConsumerState<ManagedAppsTab>
    with WidgetsBindingObserver {
  final Set<String> _selectedPackages = {};

  bool get _isSelecting => _selectedPackages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-start service if toggle is on (covers cold start / process restart).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ensureServiceRunning(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User came back from permission settings (or any other app).
      _ensureServiceRunning();
    }
  }

  /// If the toggle is on, checks permissions and starts the service silently.
  /// Shows permission dialogs only when triggered by the toggle itself.
  Future<void> _ensureServiceRunning() async {
    final settings = ref.read(settingsProvider);
    if (!settings.globalEnabled) return;

    final hasUsage = await FricarePlatform.hasUsageStatsPermission();
    final hasOverlay = await FricarePlatform.hasOverlayPermission();
    if (!hasUsage || !hasOverlay) return;

    final running = await FricarePlatform.isServiceRunning();
    if (!running) {
      await FricarePlatform.startMonitoringService();
    }
  }

  /// Called when the user explicitly flips the toggle.
  Future<void> _toggleService(BuildContext context, bool enabled) async {
    if (!enabled) {
      await FricarePlatform.stopMonitoringService();
      return;
    }

    // Check usage stats permission.
    final hasUsage = await FricarePlatform.hasUsageStatsPermission();
    if (!hasUsage) {
      if (!context.mounted) return;
      await _showPermissionDialog(
        context,
        icon: Icons.bar_chart,
        title: 'Usage Access Required',
        reason:
            'Fricare needs to see which app is in the foreground so it '
            'can show a friction challenge before the app opens.\n\n'
            'On the next screen, find Fricare and enable usage access.',
        onGrant: FricarePlatform.requestUsageStatsPermission,
      );
      // Don't start yet — _ensureServiceRunning will pick it up when the user
      // comes back from settings via the lifecycle observer.
      return;
    }

    // Check overlay (draw over other apps) permission.
    final hasOverlay = await FricarePlatform.hasOverlayPermission();
    if (!hasOverlay) {
      if (!context.mounted) return;
      await _showPermissionDialog(
        context,
        icon: Icons.layers,
        title: 'Display Over Apps Required',
        reason:
            'Fricare needs to display the friction challenge on top of '
            'the app you are opening.\n\n'
            'On the next screen, enable "Allow display over other apps".',
        onGrant: FricarePlatform.requestOverlayPermission,
      );
      return;
    }

    // Request battery optimization exemption for reliable background operation.
    final isBatteryOptimized = await FricarePlatform.isBatteryOptimized();
    if (isBatteryOptimized) {
      if (!context.mounted) return;
      await _showPermissionDialog(
        context,
        icon: Icons.battery_saver,
        title: 'Disable Battery Optimization',
        reason:
            'Fricare needs to run in the background to detect app launches. '
            'Without this, Android may kill the service when the app is closed.\n\n'
            'On the next screen, allow Fricare to run unrestricted.',
        onGrant: FricarePlatform.requestBatteryOptimizationExemption,
      );
    }

    await FricarePlatform.startMonitoringService();
  }

  Future<void> _showPermissionDialog(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String reason,
    required Future<void> Function() onGrant,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: Icon(icon, size: 36),
            title: Text(title),
            content: Text(reason),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
    if (result == true) {
      await onGrant();
    }
  }

  Future<bool> _confirmRemove(
    BuildContext context, {
    required int count,
    String? appName,
  }) async {
    final isSingle = count == 1;
    final title = isSingle ? 'Remove app?' : 'Remove $count apps?';
    final message =
        isSingle
            ? 'Remove ${appName ?? 'this app'}? '
                'This will delete all friction settings for this app.'
            : 'Remove $count apps? '
                'This will delete all friction settings for these apps.';

    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: Icon(
              Icons.delete_outline,
              size: 36,
              color: Theme.of(ctx).colorScheme.error,
            ),
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  void _toggleSelection(String packageName) {
    setState(() {
      if (_selectedPackages.contains(packageName)) {
        _selectedPackages.remove(packageName);
      } else {
        _selectedPackages.add(packageName);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedPackages.clear());
  }

  void _selectAll(List<String> allPackages) {
    setState(() {
      if (_selectedPackages.length == allPackages.length) {
        _selectedPackages.clear();
      } else {
        _selectedPackages
          ..clear()
          ..addAll(allPackages);
      }
    });
  }

  Future<void> _toggleSelected() async {
    final notifier = ref.read(frictionAppsProvider.notifier);
    final apps = ref.read(frictionAppsProvider);
    // Toggle to opposite of majority state.
    final enabledCount =
        apps
            .where(
              (a) => _selectedPackages.contains(a.packageName) && a.enabled,
            )
            .length;
    final newEnabled = enabledCount <= _selectedPackages.length / 2;
    for (final pkg in _selectedPackages) {
      await notifier.toggleApp(pkg, newEnabled);
    }
    _clearSelection();
  }

  Future<void> _deleteSelected() async {
    if (!mounted) return;
    final count = _selectedPackages.length;
    final confirmed = await _confirmRemove(context, count: count);
    if (!confirmed) return;

    final notifier = ref.read(frictionAppsProvider.notifier);
    for (final pkg in _selectedPackages.toList()) {
      await notifier.removeApp(pkg);
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final frictionApps = ref.watch(frictionAppsProvider);
    final icons = ref.watch(appIconsProvider);
    final theme = Theme.of(context);

    // Clean up selection if apps were removed externally.
    final currentPackages = frictionApps.map((a) => a.packageName).toSet();
    _selectedPackages.retainAll(currentPackages);

    return CustomScrollView(
      slivers: [
        // ── Global friction toggle ───────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      settings.globalEnabled
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : theme.colorScheme.outlineVariant,
                ),
              ),
              child: SwitchListTile(
                secondary: Icon(
                  settings.globalEnabled ? Icons.shield : Icons.shield_outlined,
                  color:
                      settings.globalEnabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                ),
                title: Text(
                  settings.globalEnabled
                      ? 'Friction is active'
                      : 'Friction is paused',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        settings.globalEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                subtitle: Text(
                  settings.globalEnabled
                      ? 'Managed apps will require friction before opening'
                      : 'All friction paused — your settings are preserved',
                  style: theme.textTheme.bodySmall,
                ),
                value: settings.globalEnabled,
                onChanged: (value) async {
                  await ref.read(settingsProvider.notifier).toggleGlobal(value);
                  if (context.mounted) await _toggleService(context, value);
                },
              ),
            ),
          ),
        ),

        if (frictionApps.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    size: 64,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No apps managed yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go to Browse to add apps',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // ── Selection bar / count header ──────────────────────────
          SliverToBoxAdapter(
            child:
                _isSelecting
                    ? _SelectionBar(
                      selectedCount: _selectedPackages.length,
                      totalCount: frictionApps.length,
                      onSelectAll:
                          () => _selectAll(
                            frictionApps.map((a) => a.packageName).toList(),
                          ),
                      onToggle: _toggleSelected,
                      onDelete: _deleteSelected,
                      onClose: _clearSelection,
                    )
                    : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                      child: Text(
                        '${frictionApps.length} app${frictionApps.length == 1 ? '' : 's'} managed',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
          ),

          // ── App list ─────────────────────────────────────────────
          SliverList.builder(
            itemCount: frictionApps.length,
            itemBuilder: (context, index) {
              final app = frictionApps[index];
              final selected = _selectedPackages.contains(app.packageName);

              return _ManagedAppTile(
                key: ValueKey(app.packageName),
                appName: app.appName,
                packageName: app.packageName,
                icon: icons[app.packageName],
                enabled: app.enabled,
                config: app.frictionConfig,
                isSelecting: _isSelecting,
                isSelected: selected,
                onToggleEnabled:
                    (v) => ref
                        .read(frictionAppsProvider.notifier)
                        .toggleApp(app.packageName, v),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                AppConfigScreen(packageName: app.packageName),
                      ),
                    ),
                onLongPress: () => _toggleSelection(app.packageName),
                onSelect: () => _toggleSelection(app.packageName),
              );
            },
          ),
        ],
      ],
    );
  }
}

// ── Selection action bar ──────────────────────────────────────────────

class _SelectionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const _SelectionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onToggle,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected = selectedCount == totalCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                tooltip: 'Cancel selection',
              ),
              Text(
                '$selectedCount selected',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
                onPressed: onSelectAll,
                tooltip: allSelected ? 'Deselect all' : 'Select all',
              ),
              IconButton(
                icon: const Icon(Icons.toggle_on_outlined),
                onPressed: onToggle,
                tooltip: 'Toggle selected',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: onDelete,
                tooltip: 'Remove selected',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual app tile ───────────────────────────────────────────────

class _ManagedAppTile extends StatelessWidget {
  final String appName;
  final String packageName;
  final Uint8List? icon;
  final bool enabled;
  final FrictionConfig config;
  final bool isSelecting;
  final bool isSelected;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSelect;

  const _ManagedAppTile({
    super.key,
    required this.appName,
    required this.packageName,
    this.icon,
    required this.enabled,
    required this.config,
    required this.isSelecting,
    required this.isSelected,
    required this.onToggleEnabled,
    required this.onTap,
    required this.onLongPress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: isSelecting ? onSelect : onTap,
      onLongPress: isSelecting ? null : onLongPress,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelecting)
            Checkbox(value: isSelected, onChanged: (_) => onSelect()),
          _AppIcon(icon: icon, size: 36),
        ],
      ),
      title: Text(
        appName,
        style: enabled ? null : TextStyle(color: theme.disabledColor),
      ),
      subtitle: Row(
        children: [
          Flexible(
            child:
                config.chainSteps.isNotEmpty
                    ? _ChainChip(config.chainSteps)
                    : _KindChip(config.kind),
          ),
        ],
      ),
      trailing:
          isSelecting
              ? null
              : Switch(value: enabled, onChanged: onToggleEnabled),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────

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

class _KindChip extends StatelessWidget {
  final FrictionKind kind;
  const _KindChip(this.kind);

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (kind) {
      FrictionKind.holdToOpen => ('Hold', Icons.touch_app),
      FrictionKind.puzzle => ('Puzzle', Icons.grid_view),
      FrictionKind.confirmation => ('Confirm', Icons.help_outline),
      FrictionKind.math => ('Math', Icons.calculate),
      FrictionKind.none => ('None', Icons.block),
    };
    return Chip(
      avatar: Icon(icon, size: 12),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _ChainChip extends StatelessWidget {
  final List<ChainStep> steps;
  const _ChainChip(this.steps);

  static String _kindShort(FrictionKind kind) => switch (kind) {
    FrictionKind.holdToOpen => 'Hold',
    FrictionKind.puzzle => 'Puzzle',
    FrictionKind.confirmation => 'Confirm',
    FrictionKind.math => 'Math',
    FrictionKind.none => 'None',
  };

  @override
  Widget build(BuildContext context) {
    final label = steps.map((s) => _kindShort(s.kind)).join(' \u2192 ');
    return Chip(
      avatar: const Icon(Icons.link, size: 12),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
