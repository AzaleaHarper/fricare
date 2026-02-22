import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/friction_type.dart';
import '../providers/friction_apps_provider.dart';
import '../widgets/delay_slider.dart' show ValueSlider;
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

          // ── Friction type ──────────────────────────────────────────
          const _SectionHeader('Friction Type'),
          const SizedBox(height: 8),
          ...[
            FrictionKind.holdToOpen,
            FrictionKind.puzzle,
            FrictionKind.confirmation,
            FrictionKind.math,
          ].map(
            (k) => RadioListTile<FrictionKind>(
              title: Text(_kindLabel(k)),
              subtitle: Text(_kindDesc(k)),
              value: k,
              groupValue: config.kind,
              onChanged: (v) {
                if (v != null) {
                  notifier.updateFrictionConfig(packageName, kind: v);
                }
              },
            ),
          ),
          const Divider(),

          // ── Intensity ──────────────────────────────────────────────
          if (config.kind == FrictionKind.holdToOpen) ...[
            ValueSlider(
              label: 'Hold duration',
              value: config.delaySeconds,
              onChanged:
                  (v) => notifier.updateFrictionConfig(
                    packageName,
                    delaySeconds: v,
                  ),
            ),
            const SizedBox(height: 8),
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
          if (config.kind == FrictionKind.puzzle) ...[
            ValueSlider(
              label: 'Number of taps',
              suffix: '',
              value: config.puzzleTaps,
              min: 3,
              max: 12,
              onChanged:
                  (v) =>
                      notifier.updateFrictionConfig(packageName, puzzleTaps: v),
            ),
          ],
          if (config.kind == FrictionKind.confirmation) ...[
            const _SectionHeader('Confirmation Steps'),
            Slider(
              value: config.confirmationSteps.toDouble(),
              min: 1,
              max: 3,
              divisions: 2,
              label:
                  '${config.confirmationSteps} step${config.confirmationSteps > 1 ? 's' : ''}',
              onChanged:
                  (v) => notifier.updateFrictionConfig(
                    packageName,
                    confirmationSteps: v.round(),
                  ),
            ),
          ],
          if (config.kind == FrictionKind.math) ...[
            ValueSlider(
              label: 'Problems to solve',
              suffix: '',
              value: config.mathProblems,
              min: 1,
              max: 5,
              onChanged:
                  (v) => notifier.updateFrictionConfig(
                    packageName,
                    mathProblems: v,
                  ),
            ),
          ],
          const Divider(),

          // ── When to apply ──────────────────────────────────────────
          const _SectionHeader('When to Apply'),
          const SizedBox(height: 8),
          ...FrictionMode.values.map(
            (m) => RadioListTile<FrictionMode>(
              title: Text(_modeLabel(m)),
              subtitle: Text(_modeDesc(m)),
              value: m,
              groupValue: config.mode,
              onChanged: (v) {
                if (v != null) {
                  notifier.updateFrictionConfig(packageName, mode: v);
                }
              },
            ),
          ),

          // Free opens threshold (only for afterOpens mode)
          if (config.mode == FrictionMode.afterOpens) ...[
            const SizedBox(height: 4),
            _SectionHeader('Free Opens Per Day: ${config.openThreshold}'),
            Slider(
              value: config.openThreshold.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${config.openThreshold}',
              onChanged:
                  (v) => notifier.updateFrictionConfig(
                    packageName,
                    openThreshold: v.round(),
                  ),
            ),
          ],

          // Escalation tier editor (only for escalating mode)
          if (config.mode == FrictionMode.escalating) ...[
            const SizedBox(height: 8),
            _EscalationEditor(
              steps: config.escalationSteps,
              onStepsChanged:
                  (steps) => notifier.updateFrictionConfig(
                    packageName,
                    escalationSteps: steps,
                  ),
            ),
          ],

          const Divider(),

          // ── Challenge chain ─────────────────────────────────────────
          const _SectionHeader('Challenge Chain'),
          const SizedBox(height: 4),
          SwitchListTile(
            title: const Text('Enable chain mode'),
            subtitle: const Text('Run multiple challenges in sequence'),
            value: config.chainSteps.isNotEmpty,
            onChanged: (v) {
              if (v) {
                notifier.updateFrictionConfig(
                  packageName,
                  chainSteps: [
                    ChainStep(
                      kind: config.kind,
                      delaySeconds: config.delaySeconds,
                      puzzleTaps: config.puzzleTaps,
                      confirmationSteps: config.confirmationSteps,
                      mathProblems: config.mathProblems,
                    ),
                  ],
                );
              } else {
                notifier.updateFrictionConfig(packageName, chainSteps: []);
              }
            },
          ),
          if (config.chainSteps.isNotEmpty)
            _ChainEditor(
              steps: config.chainSteps,
              onStepsChanged:
                  (steps) => notifier.updateFrictionConfig(
                    packageName,
                    chainSteps: steps,
                  ),
            ),

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
        ],
      ),
    );
  }

  String _kindLabel(FrictionKind k) => switch (k) {
    FrictionKind.holdToOpen => 'Hold to Open',
    FrictionKind.puzzle => 'Tap Sequence',
    FrictionKind.confirmation => 'Multi-Step Confirmation',
    FrictionKind.math => 'Math Challenge',
    FrictionKind.none => 'None',
  };

  String _kindDesc(FrictionKind k) => switch (k) {
    FrictionKind.holdToOpen => 'Hold a button for the configured delay',
    FrictionKind.puzzle => 'Complete a tap-sequence grid puzzle',
    FrictionKind.confirmation => 'Tap through "Are you sure?" screens',
    FrictionKind.math => 'Solve arithmetic problems to proceed',
    FrictionKind.none => 'No friction',
  };

  String _modeLabel(FrictionMode m) => switch (m) {
    FrictionMode.always => 'Always',
    FrictionMode.afterOpens => 'After free opens',
    FrictionMode.escalating => 'Escalating',
  };

  String _modeDesc(FrictionMode m) => switch (m) {
    FrictionMode.always => 'Apply friction every time',
    FrictionMode.afterOpens =>
      'First N opens per day are free, then friction starts',
    FrictionMode.escalating => 'Friction intensifies with each open today',
  };
}

// ── Escalation tier editor ───────────────────────────────────────────────────

class _EscalationEditor extends StatelessWidget {
  final List<EscalationStep> steps;
  final ValueChanged<List<EscalationStep>> onStepsChanged;

  const _EscalationEditor({required this.steps, required this.onStepsChanged});

  void _updateStep(int index, EscalationStep updated) {
    final next = [...steps];
    next[index] = updated;
    onStepsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Escalation Tiers',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed:
                      () => onStepsChanged(
                        EscalationStep.defaultsFor(FrictionKind.holdToOpen),
                      ),
                  child: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Define what friction level applies at each open count today.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              return _TierRow(
                step: step,
                isFirst: i == 0,
                nextFromOpen:
                    i + 1 < steps.length ? steps[i + 1].fromOpen : null,
                onKindChanged: (k) => _updateStep(i, step.copyWith(kind: k)),
                onFromOpenChanged:
                    (v) => _updateStep(i, step.copyWith(fromOpen: v)),
                onDelayChanged:
                    (v) => _updateStep(i, step.copyWith(delaySeconds: v)),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final EscalationStep step;
  final bool isFirst;
  final int? nextFromOpen;
  final ValueChanged<FrictionKind> onKindChanged;
  final ValueChanged<int> onFromOpenChanged;
  final ValueChanged<int> onDelayChanged;

  const _TierRow({
    required this.step,
    required this.isFirst,
    this.nextFromOpen,
    required this.onKindChanged,
    required this.onFromOpenChanged,
    required this.onDelayChanged,
  });

  static const _kindLabels = {
    FrictionKind.none: 'No friction',
    FrictionKind.holdToOpen: 'Hold',
    FrictionKind.puzzle: 'Puzzle',
    FrictionKind.confirmation: 'Confirm',
    FrictionKind.math: 'Math',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rangeLabel =
        nextFromOpen != null
            ? 'Opens ${step.fromOpen}–${nextFromOpen! - 1}'
            : 'Opens ${step.fromOpen}+';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line + dot
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (nextFromOpen != null)
                Container(width: 2, height: 48, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Range label + from-open stepper (not shown for first tier)
                Row(
                  children: [
                    Text(
                      rangeLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (!isFirst) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed:
                            step.fromOpen > 2
                                ? () => onFromOpenChanged(step.fromOpen - 1)
                                : null,
                      ),
                      Text('${step.fromOpen}'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add, size: 16),
                        onPressed:
                            (nextFromOpen == null ||
                                    step.fromOpen < nextFromOpen! - 1)
                                ? () => onFromOpenChanged(step.fromOpen + 1)
                                : null,
                      ),
                    ],
                  ],
                ),
                // Kind selector
                DropdownButtonFormField<FrictionKind>(
                  value: step.kind,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      FrictionKind.values
                          .map(
                            (k) => DropdownMenuItem(
                              value: k,
                              child: Text(_kindLabels[k]!),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) onKindChanged(v);
                  },
                ),
                // Delay (only if hold-to-open)
                if (step.kind == FrictionKind.holdToOpen) ...[
                  const SizedBox(height: 4),
                  ValueSlider(
                    label: 'Delay',
                    value: step.delaySeconds,
                    onChanged: onDelayChanged,
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
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Chain Steps',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Complete each challenge in order to proceed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 40, color: Colors.grey.shade300),
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
                        value: step.kind,
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
                          color: Colors.grey.shade500,
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
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}
