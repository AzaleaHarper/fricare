import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_type.dart';

void main() {
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
}
