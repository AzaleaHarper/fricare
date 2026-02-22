import 'package:flutter_test/flutter_test.dart';
import 'package:fricare/domain/models/friction_type.dart';

void main() {
  group('ChainStep serialization', () {
    test('toJson() serializes all fields with correct keys', () {
      const step = ChainStep(
        kind: FrictionKind.holdToOpen,
        delaySeconds: 5,
        puzzleTaps: 7,
        confirmationSteps: 3,
        mathProblems: 2,
      );
      final json = step.toJson();

      expect(json['kind'], 1); // holdToOpen index
      expect(json['delaySeconds'], 5);
      expect(json['puzzleTaps'], 7);
      expect(json['confirmationSteps'], 3);
      expect(json['mathProblems'], 2);
    });

    test('fromJson() deserializes all fields correctly', () {
      final json = {
        'kind': 2, // puzzle
        'delaySeconds': 10,
        'puzzleTaps': 8,
        'confirmationSteps': 4,
        'mathProblems': 5,
      };
      final step = ChainStep.fromJson(json);

      expect(step.kind, FrictionKind.puzzle);
      expect(step.delaySeconds, 10);
      expect(step.puzzleTaps, 8);
      expect(step.confirmationSteps, 4);
      expect(step.mathProblems, 5);
    });

    test('fromJson() uses defaults for missing optional fields', () {
      final step = ChainStep.fromJson({'kind': 3});

      expect(step.kind, FrictionKind.confirmation);
      expect(step.delaySeconds, 3);
      expect(step.puzzleTaps, 5);
      expect(step.confirmationSteps, 2);
      expect(step.mathProblems, 3);
    });

    test('toJson/fromJson roundtrip preserves all FrictionKind values', () {
      for (final kind in FrictionKind.values) {
        final step = ChainStep(kind: kind);
        final roundtripped = ChainStep.fromJson(step.toJson());
        expect(roundtripped.kind, kind, reason: 'Roundtrip failed for $kind');
      }
    });

    test('fromJson handles num types (double from native JSON)', () {
      final step = ChainStep.fromJson({
        'kind': 4.0, // math as double
        'delaySeconds': 5.0,
        'puzzleTaps': 7.0,
        'confirmationSteps': 3.0,
        'mathProblems': 2.0,
      });

      expect(step.kind, FrictionKind.math);
      expect(step.delaySeconds, 5);
      expect(step.puzzleTaps, 7);
    });
  });

  group('ChainStep.copyWith()', () {
    test('replaces specified fields only', () {
      const original = ChainStep(
        kind: FrictionKind.holdToOpen,
        delaySeconds: 3,
        puzzleTaps: 5,
      );
      final copy = original.copyWith(kind: FrictionKind.math);

      expect(copy.kind, FrictionKind.math);
      expect(copy.delaySeconds, 3); // unchanged
      expect(copy.puzzleTaps, 5); // unchanged
    });
  });
}
