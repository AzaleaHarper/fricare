import 'package:hive_flutter/hive_flutter.dart';

part 'friction_type.g.dart';

@HiveType(typeId: 0)
enum FrictionKind {
  @HiveField(0)
  holdToOpen,

  @HiveField(1)
  puzzle,

  @HiveField(2)
  confirmation,

  /// No friction — used in escalation tiers to represent a free open.
  @HiveField(3)
  none,

  @HiveField(4)
  math,
}

/// Controls when friction is applied relative to how many times the app has
/// been opened today.
@HiveType(typeId: 4)
enum FrictionMode {
  /// Show friction on every open (default).
  @HiveField(0)
  always,

  /// First [FrictionConfig.openThreshold] opens per day are free; friction
  /// kicks in only after that.
  @HiveField(1)
  afterOpens,

  /// Friction intensifies progressively with each open, per
  /// [FrictionConfig.escalationSteps].
  @HiveField(2)
  escalating,
}

/// A single tier in an escalation ladder.
@HiveType(typeId: 5)
class EscalationStep {
  /// Friction applies from this open number onwards (1-indexed).
  @HiveField(0)
  final int fromOpen;

  @HiveField(1)
  final FrictionKind kind;

  @HiveField(2)
  final int delaySeconds;

  const EscalationStep({
    required this.fromOpen,
    required this.kind,
    required this.delaySeconds,
  });

  EscalationStep copyWith({
    int? fromOpen,
    FrictionKind? kind,
    int? delaySeconds,
  }) =>
      EscalationStep(
        fromOpen: fromOpen ?? this.fromOpen,
        kind: kind ?? this.kind,
        delaySeconds: delaySeconds ?? this.delaySeconds,
      );

  /// Sensible default ladder: free → light → full.
  static List<EscalationStep> defaultsFor(FrictionKind heavyKind) => [
        const EscalationStep(
            fromOpen: 1, kind: FrictionKind.none, delaySeconds: 0),
        const EscalationStep(
            fromOpen: 3, kind: FrictionKind.holdToOpen, delaySeconds: 3),
        EscalationStep(fromOpen: 6, kind: heavyKind, delaySeconds: 8),
      ];
}

/// A single step in a friction chain sequence.
@HiveType(typeId: 6)
class ChainStep {
  @HiveField(0)
  final FrictionKind kind;

  @HiveField(1)
  final int delaySeconds;

  @HiveField(2)
  final int puzzleTaps;

  @HiveField(3)
  final int confirmationSteps;

  @HiveField(4)
  final int mathProblems;

  const ChainStep({
    required this.kind,
    this.delaySeconds = 3,
    this.puzzleTaps = 5,
    this.confirmationSteps = 2,
    this.mathProblems = 3,
  });

  ChainStep copyWith({
    FrictionKind? kind,
    int? delaySeconds,
    int? puzzleTaps,
    int? confirmationSteps,
    int? mathProblems,
  }) =>
      ChainStep(
        kind: kind ?? this.kind,
        delaySeconds: delaySeconds ?? this.delaySeconds,
        puzzleTaps: puzzleTaps ?? this.puzzleTaps,
        confirmationSteps: confirmationSteps ?? this.confirmationSteps,
        mathProblems: mathProblems ?? this.mathProblems,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.index,
        'delaySeconds': delaySeconds,
        'puzzleTaps': puzzleTaps,
        'confirmationSteps': confirmationSteps,
        'mathProblems': mathProblems,
      };

  static ChainStep fromJson(Map<String, dynamic> json) => ChainStep(
        kind: FrictionKind.values[(json['kind'] as num).toInt()],
        delaySeconds: (json['delaySeconds'] as num?)?.toInt() ?? 3,
        puzzleTaps: (json['puzzleTaps'] as num?)?.toInt() ?? 5,
        confirmationSteps: (json['confirmationSteps'] as num?)?.toInt() ?? 2,
        mathProblems: (json['mathProblems'] as num?)?.toInt() ?? 3,
      );
}

@HiveType(typeId: 1)
class FrictionConfig extends HiveObject {
  // ── Friction type (used for always / afterOpens modes) ────────────────────
  @HiveField(0)
  FrictionKind kind;

  @HiveField(1)
  int delaySeconds;

  @HiveField(2)
  bool randomize;

  /// +/- range in seconds when [randomize] is true.
  @HiveField(7)
  int randomizeRange;

  @HiveField(3)
  int confirmationSteps;

  // ── Dynamic friction ──────────────────────────────────────────────────────
  @HiveField(4)
  FrictionMode mode;

  /// For [FrictionMode.afterOpens]: number of free opens per day before
  /// friction activates.
  @HiveField(5)
  int openThreshold;

  /// For [FrictionMode.escalating]: ordered list of friction tiers.
  @HiveField(6)
  List<EscalationStep> escalationSteps;

  @HiveField(8)
  int puzzleTaps;

  @HiveField(9)
  int mathProblems;

  @HiveField(10)
  List<ChainStep> chainSteps;

  FrictionConfig({
    required this.kind,
    this.delaySeconds = 3,
    this.randomize = false,
    this.randomizeRange = 2,
    this.confirmationSteps = 2,
    this.puzzleTaps = 5,
    this.mathProblems = 3,
    this.mode = FrictionMode.always,
    this.openThreshold = 3,
    List<EscalationStep>? escalationSteps,
    List<ChainStep>? chainSteps,
  })  : escalationSteps =
            escalationSteps ?? EscalationStep.defaultsFor(kind),
        chainSteps = chainSteps ?? [];

  /// Effective delay accounting for optional randomization.
  int get effectiveDelay {
    if (!randomize || randomizeRange <= 0) return delaySeconds;
    final spread = randomizeRange * 2 + 1;
    final offset = (DateTime.now().microsecond % spread) - randomizeRange;
    return (delaySeconds + offset).clamp(1, 999);
  }

  /// Given how many times the app has been opened today, return the
  /// [FrictionKind] that should be shown. Returns [FrictionKind.none] to
  /// skip friction entirely.
  FrictionKind kindForOpenCount(int openCount) {
    switch (mode) {
      case FrictionMode.always:
        return kind;
      case FrictionMode.afterOpens:
        return openCount > openThreshold ? kind : FrictionKind.none;
      case FrictionMode.escalating:
        // Walk tiers in reverse to find the highest applicable one.
        final sorted = [...escalationSteps]
          ..sort((a, b) => b.fromOpen.compareTo(a.fromOpen));
        for (final step in sorted) {
          if (openCount >= step.fromOpen) return step.kind;
        }
        return FrictionKind.none;
    }
  }

  FrictionConfig copyWith({
    FrictionKind? kind,
    int? delaySeconds,
    bool? randomize,
    int? randomizeRange,
    int? confirmationSteps,
    int? puzzleTaps,
    int? mathProblems,
    FrictionMode? mode,
    int? openThreshold,
    List<EscalationStep>? escalationSteps,
    List<ChainStep>? chainSteps,
  }) {
    return FrictionConfig(
      kind: kind ?? this.kind,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      randomize: randomize ?? this.randomize,
      randomizeRange: randomizeRange ?? this.randomizeRange,
      confirmationSteps: confirmationSteps ?? this.confirmationSteps,
      puzzleTaps: puzzleTaps ?? this.puzzleTaps,
      mathProblems: mathProblems ?? this.mathProblems,
      mode: mode ?? this.mode,
      openThreshold: openThreshold ?? this.openThreshold,
      escalationSteps: escalationSteps ?? [...this.escalationSteps],
      chainSteps: chainSteps ?? [...this.chainSteps],
    );
  }
}
