import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_type.dart';

void main() {
  group('FrictionConfig.kindForOpenCount()', () {
    test('always mode returns configured kind regardless of count', () {
      final config = FrictionConfig(
        kind: FrictionKind.puzzle,
        mode: FrictionMode.always,
      );
      expect(config.kindForOpenCount(0), FrictionKind.puzzle);
      expect(config.kindForOpenCount(1), FrictionKind.puzzle);
      expect(config.kindForOpenCount(100), FrictionKind.puzzle);
    });

    test('afterOpens mode returns none when at or under threshold', () {
      final config = FrictionConfig(
        kind: FrictionKind.holdToOpen,
        mode: FrictionMode.afterOpens,
        openThreshold: 3,
      );
      expect(config.kindForOpenCount(1), FrictionKind.none);
      expect(config.kindForOpenCount(2), FrictionKind.none);
      expect(config.kindForOpenCount(3), FrictionKind.none);
    });

    test('afterOpens mode returns kind when over threshold', () {
      final config = FrictionConfig(
        kind: FrictionKind.holdToOpen,
        mode: FrictionMode.afterOpens,
        openThreshold: 3,
      );
      expect(config.kindForOpenCount(4), FrictionKind.holdToOpen);
      expect(config.kindForOpenCount(10), FrictionKind.holdToOpen);
    });

    test('escalating mode walks tiers to find highest applicable', () {
      final config = FrictionConfig(
        kind: FrictionKind.puzzle,
        mode: FrictionMode.escalating,
        escalationSteps: [
          const EscalationStep(
            fromOpen: 1,
            kind: FrictionKind.none,
            delaySeconds: 0,
          ),
          const EscalationStep(
            fromOpen: 3,
            kind: FrictionKind.holdToOpen,
            delaySeconds: 3,
          ),
          const EscalationStep(
            fromOpen: 6,
            kind: FrictionKind.puzzle,
            delaySeconds: 8,
          ),
        ],
      );

      expect(config.kindForOpenCount(1), FrictionKind.none);
      expect(config.kindForOpenCount(2), FrictionKind.none);
      expect(config.kindForOpenCount(3), FrictionKind.holdToOpen);
      expect(config.kindForOpenCount(5), FrictionKind.holdToOpen);
      expect(config.kindForOpenCount(6), FrictionKind.puzzle);
      expect(config.kindForOpenCount(99), FrictionKind.puzzle);
    });

    test('escalating mode returns none when below all tiers', () {
      final config = FrictionConfig(
        kind: FrictionKind.puzzle,
        mode: FrictionMode.escalating,
        escalationSteps: [
          const EscalationStep(
            fromOpen: 3,
            kind: FrictionKind.holdToOpen,
            delaySeconds: 3,
          ),
        ],
      );
      expect(config.kindForOpenCount(0), FrictionKind.none);
      expect(config.kindForOpenCount(1), FrictionKind.none);
      expect(config.kindForOpenCount(2), FrictionKind.none);
    });

    test('escalating mode skips tiers with kind none', () {
      final config = FrictionConfig(
        kind: FrictionKind.puzzle,
        mode: FrictionMode.escalating,
        escalationSteps: [
          const EscalationStep(
            fromOpen: 1,
            kind: FrictionKind.none,
            delaySeconds: 0,
          ),
          const EscalationStep(
            fromOpen: 5,
            kind: FrictionKind.none,
            delaySeconds: 0,
          ),
        ],
      );
      // All tiers resolve to none kind → returns none
      expect(config.kindForOpenCount(5), FrictionKind.none);
    });
  });

  group('FrictionConfig.effectiveDelay', () {
    test('returns delaySeconds when randomize is false', () {
      final config = FrictionConfig(
        kind: FrictionKind.holdToOpen,
        delaySeconds: 5,
        randomize: false,
      );
      expect(config.effectiveDelay, 5);
    });

    test('returns delaySeconds when randomizeRange is 0', () {
      final config = FrictionConfig(
        kind: FrictionKind.holdToOpen,
        delaySeconds: 5,
        randomize: true,
        randomizeRange: 0,
      );
      expect(config.effectiveDelay, 5);
    });

    test('clamps to minimum 1 with randomization', () {
      final config = FrictionConfig(
        kind: FrictionKind.holdToOpen,
        delaySeconds: 1,
        randomize: true,
        randomizeRange: 5,
      );
      // Run multiple times - should always be >= 1
      for (var i = 0; i < 50; i++) {
        expect(config.effectiveDelay, greaterThanOrEqualTo(1));
      }
    });
  });

  group('FrictionConfig.copyWith()', () {
    test('preserves all fields when no arguments passed', () {
      final config = FrictionConfig(
        kind: FrictionKind.math,
        delaySeconds: 10,
        randomize: true,
        randomizeRange: 4,
        confirmationSteps: 5,
        puzzleTaps: 8,
        mathProblems: 4,
        mode: FrictionMode.afterOpens,
        openThreshold: 7,
        chainSteps: [const ChainStep(kind: FrictionKind.holdToOpen)],
      );
      final copy = config.copyWith();

      expect(copy.kind, config.kind);
      expect(copy.delaySeconds, config.delaySeconds);
      expect(copy.randomize, config.randomize);
      expect(copy.randomizeRange, config.randomizeRange);
      expect(copy.confirmationSteps, config.confirmationSteps);
      expect(copy.puzzleTaps, config.puzzleTaps);
      expect(copy.mathProblems, config.mathProblems);
      expect(copy.mode, config.mode);
      expect(copy.openThreshold, config.openThreshold);
      expect(copy.chainSteps.length, config.chainSteps.length);
    });

    test('replaces only specified fields', () {
      final config = FrictionConfig(
        kind: FrictionKind.holdToOpen,
        delaySeconds: 3,
        puzzleTaps: 5,
      );
      final copy = config.copyWith(kind: FrictionKind.math, delaySeconds: 20);

      expect(copy.kind, FrictionKind.math);
      expect(copy.delaySeconds, 20);
      expect(copy.puzzleTaps, 5); // unchanged
    });
  });

  group('EscalationStep.defaultsFor()', () {
    test('generates 3 tiers ending with given kind', () {
      final steps = EscalationStep.defaultsFor(FrictionKind.puzzle);

      expect(steps.length, 3);
      expect(steps[0].kind, FrictionKind.none);
      expect(steps[0].fromOpen, 1);
      expect(steps[1].kind, FrictionKind.holdToOpen);
      expect(steps[1].fromOpen, 3);
      expect(steps[2].kind, FrictionKind.puzzle);
      expect(steps[2].fromOpen, 6);
    });
  });
}
