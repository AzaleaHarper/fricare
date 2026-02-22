import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/friction_type.dart';
import '../../infrastructure/platform/method_channels.dart';
import '../providers/friction_apps_provider.dart';
import '../providers/settings_provider.dart';
import 'app_config_screen.dart';

class ProtectedAppsTab extends ConsumerStatefulWidget {
  const ProtectedAppsTab({super.key});

  @override
  ConsumerState<ProtectedAppsTab> createState() => _ProtectedAppsTabState();
}

class _ProtectedAppsTabState extends ConsumerState<ProtectedAppsTab>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-start service if toggle is on (covers cold start / process restart).
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureServiceRunning());
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
        reason: 'Fricare needs to see which app is in the foreground so it '
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
        reason: 'Fricare needs to display the friction challenge on top of '
            'the app you are opening.\n\n'
            'On the next screen, enable "Allow display over other apps".',
        onGrant: FricarePlatform.requestOverlayPermission,
      );
      return;
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
      builder: (ctx) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final frictionApps = ref.watch(frictionAppsProvider);
    final icons = ref.watch(appIconsProvider);
    final theme = Theme.of(context);

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
                  color: settings.globalEnabled
                      ? theme.colorScheme.primary.withValues(alpha: 0.4)
                      : Colors.grey.shade300,
                ),
              ),
              child: SwitchListTile(
                secondary: Icon(
                  settings.globalEnabled
                      ? Icons.shield
                      : Icons.shield_outlined,
                  color: settings.globalEnabled
                      ? theme.colorScheme.primary
                      : Colors.grey,
                ),
                title: Text(
                  settings.globalEnabled
                      ? 'Friction is active'
                      : 'Friction is paused',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: settings.globalEnabled
                        ? theme.colorScheme.primary
                        : Colors.grey.shade700,
                  ),
                ),
                subtitle: Text(
                  settings.globalEnabled
                      ? 'Selected apps will require friction before opening'
                      : 'All friction paused — your settings are preserved',
                  style: theme.textTheme.bodySmall,
                ),
                value: settings.globalEnabled,
                onChanged: (value) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .toggleGlobal(value);
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
                  Icon(Icons.shield_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No apps protected yet',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    'Go to Browse to add friction to apps',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Text(
                '${frictionApps.length} app${frictionApps.length == 1 ? '' : 's'} protected',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: frictionApps.length,
            itemBuilder: (context, index) {
              final app = frictionApps[index];
              return _ProtectedAppTile(
                key: ValueKey(app.packageName),
                appName: app.appName,
                packageName: app.packageName,
                icon: icons[app.packageName],
                enabled: app.enabled,
                config: app.frictionConfig,
                onToggleEnabled: (v) => ref
                    .read(frictionAppsProvider.notifier)
                    .toggleApp(app.packageName, v),
                onRemove: () => ref
                    .read(frictionAppsProvider.notifier)
                    .removeApp(app.packageName),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AppConfigScreen(packageName: app.packageName),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ProtectedAppTile extends StatelessWidget {
  final String appName;
  final String packageName;
  final Uint8List? icon;
  final bool enabled;
  final FrictionConfig config;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _ProtectedAppTile({
    super.key,
    required this.appName,
    required this.packageName,
    this.icon,
    required this.enabled,
    required this.config,
    required this.onToggleEnabled,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: icon != null && icon!.isNotEmpty
          ? Image.memory(icon!, width: 36, height: 36)
          : const Icon(Icons.android, size: 36, color: Colors.grey),
      title: Text(
        appName,
        style: enabled ? null : TextStyle(color: theme.disabledColor),
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: config.chainSteps.isNotEmpty
                ? _ChainChip(config.chainSteps)
                : _KindChip(config.kind),
          ),
          const SizedBox(width: 6),
          _ModeChip(config),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: enabled,
            onChanged: onToggleEnabled,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.grey,
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
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
    final label = steps.map((s) => _kindShort(s.kind)).join(' → ');
    return Chip(
      avatar: const Icon(Icons.link, size: 12),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _ModeChip extends StatelessWidget {
  final FrictionConfig config;
  const _ModeChip(this.config);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (config.mode) {
      FrictionMode.always => ('Always', Colors.blue),
      FrictionMode.afterOpens =>
        ('After ${config.openThreshold} opens', Colors.orange),
      FrictionMode.escalating => ('Escalating', Colors.purple),
    };
    return Chip(
      label: Text(label,
          style: TextStyle(fontSize: 11, color: color.shade700)),
      backgroundColor: color.shade50,
      side: BorderSide(color: color.shade200),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
