import 'package:flutter_test/flutter_test.dart';
import 'package:tripl/core/math_evaluator.dart';

void main() {
  group('MathEvaluator Tests', () {
    test('Basic subtraction requested by user: 547 - 163', () {
      final res = MathEvaluator.evaluate('547 - 163');
      expect(res, equals(384.0));
      expect(MathEvaluator.formatResult(res!), equals('384'));
    });

    test('Basic addition, multiplication, division', () {
      expect(MathEvaluator.evaluate('100 + 50'), equals(150.0));
      expect(MathEvaluator.evaluate('25 * 4'), equals(100.0));
      expect(MathEvaluator.evaluate('500 / 4'), equals(125.0));
      expect(MathEvaluator.evaluate('12.5 + 4.99'), equals(17.49));
    });

    test('Unicode math symbols × and ÷ and x', () {
      expect(MathEvaluator.evaluate('25 × 4'), equals(100.0));
      expect(MathEvaluator.evaluate('500 ÷ 5'), equals(100.0));
      expect(MathEvaluator.evaluate('10 x 3'), equals(30.0));
    });

    test('Operator precedence and parentheses', () {
      expect(MathEvaluator.evaluate('10 + 5 * 2'), equals(20.0));
      expect(MathEvaluator.evaluate('(10 + 5) * 2'), equals(30.0));
      expect(MathEvaluator.evaluate('100 - (20 + 30)'), equals(50.0));
    });

    test('Percentages', () {
      expect(MathEvaluator.evaluate('15%'), equals(0.15));
      expect(MathEvaluator.evaluate('200 * 15%'), equals(30.0));
    });

    test('Invalid expressions and safety', () {
      expect(MathEvaluator.evaluate('547 - '), isNull);
      expect(MathEvaluator.evaluate('abc'), isNull);
      expect(MathEvaluator.evaluate('10 / 0'), isNull);
      expect(MathEvaluator.evaluate(''), isNull);
    });

    test('tryParseAmount helper', () {
      expect(MathEvaluator.tryParseAmount('384.50'), equals(384.50));
      expect(MathEvaluator.tryParseAmount('547 - 163'), equals(384.0));
      expect(MathEvaluator.tryParseAmount('invalid'), isNull);
    });

    test('hasOperator check', () {
      expect(MathEvaluator.hasOperator('384'), isFalse);
      expect(MathEvaluator.hasOperator('547 - 163'), isTrue);
      expect(MathEvaluator.hasOperator('100 + 50'), isTrue);
      expect(MathEvaluator.hasOperator('25 * 4'), isTrue);
    });
  });
}
