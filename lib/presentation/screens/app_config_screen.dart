import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/friction_type.dart';
import '../providers/friction_apps_provider.dart';
import '../widgets/value_slider.dart' show ValueSlider;
import 'test_friction_screen.dart';

class AppConfigScreen extends ConsumerWidget {
  final String packageName;

  const AppConfigScreen({super.key, required this.packageName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frictionApps = ref.watch(frictionAppsProvider);
    final app =
        frictionApps.where((a) => a.packageName == packageName).firstOrNull;

    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configure')),
        body: const Center(child: Text('App not found')),
      );
    }

    final config = app.frictionConfig;
    final notifier = ref.read(frictionAppsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(app.appName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Enable toggle ──────────────────────────────────────────
          SwitchListTile(
            title: const Text('Friction enabled'),
            value: app.enabled,
            onChanged: (v) => notifier.toggleApp(packageName, v),
          ),
          const Divider(),

          // ── Friction steps ─────────────────────────────────────────
          _ChainEditor(
            steps: _stepsFromConfig(config),
            onStepsChanged: (steps) => _saveSteps(notifier, packageName, steps),
          ),

          // Randomize delay (applies to hold-to-open steps)
          if (_stepsFromConfig(
            config,
          ).any((s) => s.kind == FrictionKind.holdToOpen)) ...[
            SwitchListTile(
              title: const Text('Randomize delay'),
              subtitle: Text(
                config.randomize
                    ? 'Varies by +/- ${config.randomizeRange} s each time'
                    : 'Same delay every time',
              ),
              value: config.randomize,
              onChanged:
                  (v) =>
                      notifier.updateFrictionConfig(packageName, randomize: v),
            ),
            if (config.randomize)
              ValueSlider(
                label: 'Randomize range',
                suffix: 's',
                value: config.randomizeRange,
                min: 1,
                max: 10,
                onChanged:
                    (v) => notifier.updateFrictionConfig(
                      packageName,
                      randomizeRange: v,
                    ),
              ),
          ],
          const Divider(),

          // ── Apply friction every ──────────────────────────────────────
          const _SectionHeader('Apply Friction'),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: config.cooldownMinutes == 0 ? 0 : 1,
            onChanged: (v) {
              if (v == 0) {
                notifier.updateFrictionConfig(packageName, cooldownMinutes: 0);
              } else {
                notifier.updateFrictionConfig(
                  packageName,
                  cooldownMinutes:
                      config.cooldownMinutes > 0 ? config.cooldownMinutes : 5,
                );
              }
            },
            child: const Column(
              children: [
                RadioListTile<int>(
                  title: Text('Every open'),
                  subtitle: Text('Friction each time you switch to this app'),
                  value: 0,
                ),
                RadioListTile<int>(
                  title: Text('On a timer'),
                  subtitle: Text(
                    'Free access for a set period after completing friction',
                  ),
                  value: 1,
                ),
              ],
            ),
          ),
          if (config.cooldownMinutes > 0) ...[
            const SizedBox(height: 4),
            ValueSlider(
              label: 'Cooldown',
              suffix: 'min',
              value: config.cooldownMinutes,
              min: 1,
              max: 120,
              onChanged:
                  (v) => notifier.updateFrictionConfig(
                    packageName,
                    cooldownMinutes: v,
                  ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Test button ────────────────────────────────────────────
          FilledButton.icon(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => TestFrictionScreen(
                          frictionConfig: config,
                          appName: app.appName,
                        ),
                  ),
                ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Test Friction'),
          ),

          const SizedBox(height: 16),

          // ── Remove button ──────────────────────────────────────────
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            onPressed: () => _confirmAndRemove(context, ref, app.appName),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove App'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRemove(
    BuildContext context,
    WidgetRef ref,
    String appName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: Icon(
              Icons.delete_outline,
              size: 36,
              color: Theme.of(ctx).colorScheme.error,
            ),
            title: const Text('Remove app?'),
            content: Text(
              'Remove $appName? '
              'This will delete all friction settings for this app.',
            ),
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
    if (confirmed != true) return;
    await ref.read(frictionAppsProvider.notifier).removeApp(packageName);
    if (context.mounted) Navigator.pop(context);
  }

  static List<ChainStep> _stepsFromConfig(FrictionConfig config) {
    if (config.chainSteps.isNotEmpty) return config.chainSteps;
    return [
      ChainStep(
        kind: config.kind,
        delaySeconds: config.delaySeconds,
        puzzleTaps: config.puzzleTaps,
        confirmationSteps: config.confirmationSteps,
        mathProblems: config.mathProblems,
      ),
    ];
  }

  static void _saveSteps(
    FrictionAppsNotifier notifier,
    String packageName,
    List<ChainStep> steps,
  ) {
    if (steps.length == 1) {
      final s = steps.first;
      notifier.updateFrictionConfig(
        packageName,
        kind: s.kind,
        delaySeconds: s.delaySeconds,
        puzzleTaps: s.puzzleTaps,
        confirmationSteps: s.confirmationSteps,
        mathProblems: s.mathProblems,
        chainSteps: [],
      );
    } else {
      notifier.updateFrictionConfig(packageName, chainSteps: steps);
    }
  }
}

// ── Chain editor ─────────────────────────────────────────────────────────────

class _ChainEditor extends StatelessWidget {
  final List<ChainStep> steps;
  final ValueChanged<List<ChainStep>> onStepsChanged;

  const _ChainEditor({required this.steps, required this.onStepsChanged});

  static const _kindLabels = {
    FrictionKind.holdToOpen: 'Hold',
    FrictionKind.puzzle: 'Puzzle',
    FrictionKind.confirmation: 'Confirm',
    FrictionKind.math: 'Math',
  };

  void _updateStep(int index, ChainStep updated) {
    final next = [...steps];
    next[index] = updated;
    onStepsChanged(next);
  }

  void _removeStep(int index) {
    final next = [...steps]..removeAt(index);
    onStepsChanged(next);
  }

  void _addStep() {
    onStepsChanged([...steps, const ChainStep(kind: FrictionKind.holdToOpen)]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(steps.length > 1 ? Icons.link : Icons.layers, size: 18),
                const SizedBox(width: 8),
                Text(
                  steps.length > 1 ? 'Friction Chain' : 'Friction',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              steps.length > 1
                  ? 'Complete each challenge in order to proceed.'
                  : 'Configure your friction challenge.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              return _ChainStepRow(
                index: i,
                step: step,
                isLast: i == steps.length - 1,
                canDelete: steps.length > 1,
                onKindChanged: (k) => _updateStep(i, step.copyWith(kind: k)),
                onDelayChanged:
                    (v) => _updateStep(i, step.copyWith(delaySeconds: v)),
                onPuzzleTapsChanged:
                    (v) => _updateStep(i, step.copyWith(puzzleTaps: v)),
                onConfirmStepsChanged:
                    (v) => _updateStep(i, step.copyWith(confirmationSteps: v)),
                onMathProblemsChanged:
                    (v) => _updateStep(i, step.copyWith(mathProblems: v)),
                onDelete: () => _removeStep(i),
              );
            }),
            if (steps.length < 5)
              Center(
                child: TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Step'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChainStepRow extends StatelessWidget {
  final int index;
  final ChainStep step;
  final bool isLast;
  final bool canDelete;
  final ValueChanged<FrictionKind> onKindChanged;
  final ValueChanged<int> onDelayChanged;
  final ValueChanged<int> onPuzzleTapsChanged;
  final ValueChanged<int> onConfirmStepsChanged;
  final ValueChanged<int> onMathProblemsChanged;
  final VoidCallback onDelete;

  const _ChainStepRow({
    required this.index,
    required this.step,
    required this.isLast,
    required this.canDelete,
    required this.onKindChanged,
    required this.onDelayChanged,
    required this.onPuzzleTapsChanged,
    required this.onConfirmStepsChanged,
    required this.onMathProblemsChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line + numbered dot
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<FrictionKind>(
                        initialValue: step.kind,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _ChainEditor._kindLabels.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) onKindChanged(v);
                        },
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: theme.colorScheme.outline,
                        ),
                        onPressed: onDelete,
                      ),
                  ],
                ),
                // Kind-specific parameters
                if (step.kind == FrictionKind.holdToOpen) ...[
                  const SizedBox(height: 4),
                  ValueSlider(
                    label: 'Hold',
                    value: step.delaySeconds,
                    onChanged: onDelayChanged,
                  ),
                ],
                if (step.kind == FrictionKind.puzzle) ...[
                  const SizedBox(height: 4),
                  ValueSlider(
                    label: 'Taps',
                    suffix: '',
                    value: step.puzzleTaps,
                    min: 3,
                    max: 12,
                    onChanged: onPuzzleTapsChanged,
                  ),
                ],
                if (step.kind == FrictionKind.confirmation) ...[
                  const SizedBox(height: 4),
                  ValueSlider(
                    label: 'Steps',
                    suffix: '',
                    value: step.confirmationSteps,
                    min: 1,
                    max: 3,
                    onChanged: onConfirmStepsChanged,
                  ),
                ],
                if (step.kind == FrictionKind.math) ...[
                  const SizedBox(height: 4),
                  ValueSlider(
                    label: 'Problems',
                    suffix: '',
                    value: step.mathProblems,
                    min: 1,
                    max: 5,
                    onChanged: onMathProblemsChanged,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text, style: theme.textTheme.titleMedium);
  }
}
