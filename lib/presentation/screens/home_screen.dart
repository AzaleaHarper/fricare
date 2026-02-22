import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friction_apps_provider.dart';
import 'browse_apps_tab.dart';
import 'protected_apps_tab.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frictionApps = ref.watch(frictionAppsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fricare'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Badge(
                  isLabelVisible: frictionApps.isNotEmpty,
                  label: Text('${frictionApps.length}'),
                  child: const Icon(Icons.shield_outlined),
                ),
                text: 'Protected',
              ),
              const Tab(icon: Icon(Icons.apps), text: 'Browse'),
            ],
          ),
        ),
        body: const TabBarView(children: [ProtectedAppsTab(), BrowseAppsTab()]),
      ),
    );
  }
}
