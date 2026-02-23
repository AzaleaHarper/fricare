import 'package:flutter/material.dart';

import '../../domain/models/friction_type.dart';
import 'value_slider.dart' show ValueSlider;

/// Shows a two-step bottom sheet wizard for configuring friction on a new app.
/// Returns a [FrictionConfig] on completion, or null if cancelled.
Future<FrictionConfig?> showFrictionSetupWizard(
  BuildContext context, {
  required String appName,
}) {
  return showModalBottomSheet<FrictionConfig>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FrictionSetupWizard(appName: appName),
  );
}

class _FrictionSetupWizard extends StatefulWidget {
  final String appName;
  const _FrictionSetupWizard({required this.appName});

  @override
  State<_FrictionSetupWizard> createState() => _FrictionSetupWizardState();
}

class _FrictionSetupWizardState extends State<_FrictionSetupWizard> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 2;

  // Step 1 – friction type
  FrictionKind _selectedKind = FrictionKind.holdToOpen;

  // Step 2 – friction settings
  int _delaySeconds = 3;
  bool _randomize = false;
  int _randomizeRange = 2;
  int _confirmationSteps = 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  void _confirm() {
    Navigator.of(context).pop(
      FrictionConfig(
        kind: _selectedKind,
        delaySeconds: _delaySeconds,
        randomize: _randomize,
        randomizeRange: _randomizeRange,
        confirmationSteps: _confirmationSteps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            _WizardHeader(
              appName: widget.appName,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onBack: _currentPage > 0 ? () => _goTo(_currentPage - 1) : null,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: pick friction type
                  _StepPickType(
                    selected: _selectedKind,
                    onSelect: (k) => setState(() => _selectedKind = k),
                    onNext: () => _goTo(1),
                  ),
                  // Step 2: configure intensity + confirm
                  _StepConfigure(
                    kind: _selectedKind,
                    delaySeconds: _delaySeconds,
                    randomize: _randomize,
                    randomizeRange: _randomizeRange,
                    confirmationSteps: _confirmationSteps,
                    onDelayChanged: (v) => setState(() => _delaySeconds = v),
                    onRandomizeChanged: (v) => setState(() => _randomize = v),
                    onRandomizeRangeChanged:
                        (v) => setState(() => _randomizeRange = v),
                    onStepsChanged:
                        (v) => setState(() => _confirmationSteps = v),
                    onConfirm: _confirm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wizard header ────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  final String appName;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onBack;

  const _WizardHeader({
    required this.appName,
    required this.currentPage,
    required this.totalPages,
    this.onBack,
  });

  static const _titles = ['Choose Friction Type', 'Set Intensity'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titles[currentPage.clamp(0, _titles.length - 1)],
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      appName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${currentPage + 1} / $totalPages',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Step dots
          Row(
            children: [
              const SizedBox(width: 8),
              for (int i = 0; i < totalPages; i++) ...[
                _StepDot(active: currentPage == i, done: currentPage > i),
                if (i < totalPages - 1) _StepLine(done: currentPage > i),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final color =
        done || active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 12 : 10,
      height: active ? 12 : 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 2,
      color:
          done
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ── Step 1: Pick friction type ───────────────────────────────────────────────

class _StepPickType extends StatelessWidget {
  final FrictionKind selected;
  final ValueChanged<FrictionKind> onSelect;
  final VoidCallback onNext;

  const _StepPickType({
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  static const _visibleKinds = [
    FrictionKind.holdToOpen,
    FrictionKind.puzzle,
    FrictionKind.confirmation,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children:
                  _visibleKinds.map((kind) {
                    return _FrictionTypeCard(
                      kind: kind,
                      isSelected: kind == selected,
                      onTap: () => onSelect(kind),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onNext, child: const Text('Next')),
          ),
        ],
      ),
    );
  }
}

class _FrictionTypeCard extends StatelessWidget {
  final FrictionKind kind;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrictionTypeCard({
    required this.kind,
    required this.isSelected,
    required this.onTap,
  });

  static const _meta = {
    FrictionKind.holdToOpen: (
      icon: Icons.touch_app,
      label: 'Hold to Open',
      desc: 'Hold a button for several seconds before the app opens',
    ),
    FrictionKind.puzzle: (
      icon: Icons.grid_view,
      label: 'Tap Sequence',
      desc: 'Complete a tap-sequence grid puzzle to proceed',
    ),
    FrictionKind.confirmation: (
      icon: Icons.help_outline,
      label: 'Multi-Step Confirmation',
      desc: 'Tap through multiple "Are you sure?" prompts',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _meta[kind]!;
    final color = isSelected ? theme.colorScheme.primary : Colors.transparent;
    final borderColor =
        isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(meta.icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta.desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Configure intensity ──────────────────────────────────────────────

class _StepConfigure extends StatelessWidget {
  final FrictionKind kind;
  final int delaySeconds;
  final bool randomize;
  final int randomizeRange;
  final int confirmationSteps;
  final ValueChanged<int> onDelayChanged;
  final ValueChanged<bool> onRandomizeChanged;
  final ValueChanged<int> onRandomizeRangeChanged;
  final ValueChanged<int> onStepsChanged;
  final VoidCallback onConfirm;

  const _StepConfigure({
    required this.kind,
    required this.delaySeconds,
    required this.randomize,
    required this.randomizeRange,
    required this.confirmationSteps,
    required this.onDelayChanged,
    required this.onRandomizeChanged,
    required this.onRandomizeRangeChanged,
    required this.onStepsChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              children: [
                if (kind == FrictionKind.holdToOpen) ...[
                  ValueSlider(
                    label: 'Hold duration',
                    value: delaySeconds,
                    onChanged: onDelayChanged,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Randomize delay'),
                    subtitle: Text(
                      randomize
                          ? 'Varies by +/- $randomizeRange s each time'
                          : 'Same delay every time',
                    ),
                    value: randomize,
                    onChanged: onRandomizeChanged,
                  ),
                  if (randomize) ...[
                    ValueSlider(
                      label: 'Randomize range',
                      suffix: 's',
                      value: randomizeRange,
                      min: 1,
                      max: 10,
                      onChanged: onRandomizeRangeChanged,
                    ),
                  ],
                ],
                if (kind == FrictionKind.confirmation) ...[
                  Text(
                    'Confirmation Steps',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How many "Are you sure?" screens to show',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Slider(
                    value: confirmationSteps.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label:
                        '$confirmationSteps step${confirmationSteps > 1 ? 's' : ''}',
                    onChanged: (v) => onStepsChanged(v.round()),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onConfirm,
              child: const Text('Add Friction'),
            ),
          ),
        ],
      ),
    );
  }
}
