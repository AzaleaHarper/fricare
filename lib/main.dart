import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'domain/models/friction_app.dart';
// Ensure overlay entrypoint is compiled into the Dart kernel.
export 'overlay/overlay_main.dart';
import 'domain/models/friction_settings.dart';
import 'domain/models/friction_type.dart';
import 'infrastructure/repositories/hive_friction_app_repository.dart';
import 'presentation/providers/friction_apps_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(FrictionKindAdapter());
  Hive.registerAdapter(FrictionModeAdapter());
  Hive.registerAdapter(EscalationStepAdapter());
  Hive.registerAdapter(ChainStepAdapter());
  Hive.registerAdapter(FrictionConfigAdapter());
  Hive.registerAdapter(FrictionAppAdapter());
  Hive.registerAdapter(FrictionSettingsAdapter());

  // Initialize repository
  final repository = HiveFrictionAppRepository();
  await repository.init();

  runApp(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
      ],
      child: const FricareApp(),
    ),
  );
}
