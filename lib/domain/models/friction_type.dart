import 'package:hive_flutter/hive_flutter.dart';

part 'friction_type.g.dart';

@HiveType(typeId: 0)
enum FrictionKind {
  @HiveField(0)
  none,

  @HiveField(1)
  holdToOpen,

  @HiveField(2)
  puzzle,

  @HiveField(3)
  confirmation,

  @HiveField(4)
  math,
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
  }) => ChainStep(
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

  @HiveField(8)
  int puzzleTaps;

  @HiveField(9)
  int mathProblems;

  @HiveField(10)
  List<ChainStep> chainSteps;

  /// Minutes of free access after completing friction. 0 = friction every time.
  @HiveField(11)
  int cooldownMinutes;

  FrictionConfig({
    required this.kind,
    this.delaySeconds = 3,
    this.randomize = false,
    this.randomizeRange = 2,
    this.confirmationSteps = 2,
    this.puzzleTaps = 5,
    this.mathProblems = 3,
    this.cooldownMinutes = 0,
    List<ChainStep>? chainSteps,
  }) : chainSteps = chainSteps ?? [];

  /// Effective delay accounting for optional randomization.
  int get effectiveDelay {
    if (!randomize || randomizeRange <= 0) return delaySeconds;
    final spread = randomizeRange * 2 + 1;
    final offset = (DateTime.now().microsecond % spread) - randomizeRange;
    return (delaySeconds + offset).clamp(1, 999);
  }

  FrictionConfig copyWith({
    FrictionKind? kind,
    int? delaySeconds,
    bool? randomize,
    int? randomizeRange,
    int? confirmationSteps,
    int? puzzleTaps,
    int? mathProblems,
    List<ChainStep>? chainSteps,
    int? cooldownMinutes,
  }) {
    return FrictionConfig(
      kind: kind ?? this.kind,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      randomize: randomize ?? this.randomize,
      randomizeRange: randomizeRange ?? this.randomizeRange,
      confirmationSteps: confirmationSteps ?? this.confirmationSteps,
      puzzleTaps: puzzleTaps ?? this.puzzleTaps,
      mathProblems: mathProblems ?? this.mathProblems,
      chainSteps: chainSteps ?? [...this.chainSteps],
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
    );
  }
}
