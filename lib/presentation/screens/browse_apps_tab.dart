import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friction_apps_provider.dart';
import '../widgets/app_list_tile.dart';
import 'app_config_screen.dart';

class BrowseAppsTab extends ConsumerStatefulWidget {
  const BrowseAppsTab({super.key});

  @override
  ConsumerState<BrowseAppsTab> createState() => _BrowseAppsTabState();
}

class _BrowseAppsTabState extends ConsumerState<BrowseAppsTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onAppChecked(String packageName, String appName) async {
    await ref.read(frictionAppsProvider.notifier).addApp(packageName, appName);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppConfigScreen(packageName: packageName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frictionApps = ref.watch(frictionAppsProvider);
    final installedApps = ref.watch(installedAppsProvider);
    final theme = Theme.of(context);

    return installedApps.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading apps: $err')),
      data: (apps) {
        final filtered =
            _query.isEmpty
                ? apps
                : apps
                    .where(
                      (a) =>
                          a.appName.toLowerCase().contains(_query) ||
                          a.packageName.toLowerCase().contains(_query),
                    )
                    .toList();

        return CustomScrollView(
          slivers: [
            // ── Search bar ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search apps…',
                  leading: const Icon(Icons.search, size: 20),
                  trailing:
                      _query.isNotEmpty
                          ? [
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _searchController.clear(),
                            ),
                          ]
                          : null,
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12),
                  ),
                  elevation: const WidgetStatePropertyAll(1),
                ),
              ),
            ),

            // ── Count header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
                child: Text(
                  filtered.isEmpty
                      ? 'No apps found'
                      : _query.isEmpty
                      ? '${filtered.length} apps installed'
                      : '${filtered.length} result${filtered.length == 1 ? '' : 's'} for "$_query"',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            // ── App list ─────────────────────────────────────────────
            SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final app = filtered[index];
                final frictionApp =
                    frictionApps
                        .where((a) => a.packageName == app.packageName)
                        .firstOrNull;
                final isSelected = frictionApp != null;

                return AppListTile(
                  appName: app.appName,
                  packageName: app.packageName,
                  icon: app.icon,
                  isSelected: isSelected,
                  frictionEnabled: frictionApp?.enabled,
                  frictionKind: frictionApp?.frictionConfig.kind,
                  onToggle: (selected) {
                    if (selected) {
                      _onAppChecked(app.packageName, app.appName);
                    } else {
                      ref
                          .read(frictionAppsProvider.notifier)
                          .removeApp(app.packageName);
                    }
                  },
                  onTap:
                      isSelected
                          ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AppConfigScreen(
                                    packageName: app.packageName,
                                  ),
                            ),
                          )
                          : null,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
