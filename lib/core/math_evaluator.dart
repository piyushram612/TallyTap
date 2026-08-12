import 'dart:math' as math;

/// Utility class for evaluating math expressions in amount text fields.
/// Supports basic arithmetic operations: +, -, *, x, ×, /, ÷, %, parentheses (),
/// and handles percentage operations (e.g. 1000 - 15%, 100 + 10%).
class MathEvaluator {
  /// Safely attempts to parse an input string as a double or math expression.
  /// Returns null if the expression is invalid, empty, or results in NaN/Infinity.
  static double? tryParseAmount(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // First try standard double parsing
    final directDouble = double.tryParse(trimmed);
    if (directDouble != null && !directDouble.isNaN && !directDouble.isInfinite) {
      return directDouble;
    }

    // Otherwise attempt math expression evaluation
    return evaluate(trimmed);
  }

  /// Checks if string contains operators like +, -, *, /, % (more than just a standard positive number).
  static bool hasOperator(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return false;
    // Check if there is any operator outside of a leading negative sign
    final rest = cleaned.startsWith('-') ? cleaned.substring(1) : cleaned;
    return rest.contains('+') ||
        rest.contains('-') ||
        rest.contains('*') ||
        rest.contains('×') ||
        rest.contains('x') ||
        rest.contains('X') ||
        rest.contains('/') ||
        rest.contains('÷') ||
        rest.contains('%');
  }

  /// Formats the evaluated result into a clean display string (e.g. 384 or 384.50).
  static String formatResult(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e12) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  /// Evaluates a math expression string.
  static double? evaluate(String expression) {
    if (expression.trim().isEmpty) return null;

    try {
      final sanitized = _sanitize(expression);
      if (sanitized.isEmpty) return null;

      final tokens = _tokenize(sanitized);
      if (tokens.isEmpty) return null;

      final parser = _Parser(tokens);
      final result = parser.parse();

      if (result.isNaN || result.isInfinite) return null;
      // Fix IEEE 754 precision artifacts e.g. 17.490000000000002 -> 17.49
      final cleanedResult = double.parse(result.toStringAsFixed(10));
      return cleanedResult;
    } catch (_) {
      return null;
    }
  }

  static String _sanitize(String expr) {
    return expr
        .replaceAll('×', '*')
        .replaceAll('x', '*')
        .replaceAll('X', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '');
  }

  static List<_Token> _tokenize(String expr) {
    final List<_Token> tokens = [];
    int i = 0;

    while (i < expr.length) {
      final char = expr[i];

      if (char == '+' || char == '-' || char == '*' || char == '/' || char == '(' || char == ')' || char == '%') {
        tokens.add(_Token(_TokenType.operator, char));
        i++;
      } else if (_isDigitOrDot(char)) {
        final start = i;
        while (i < expr.length && _isDigitOrDot(expr[i])) {
          i++;
        }
        final numStr = expr.substring(start, i);
        final numVal = double.tryParse(numStr);
        if (numVal == null) throw FormatException('Invalid number: $numStr');
        tokens.add(_Token(_TokenType.number, numStr, numVal));
      } else {
        // Skip unrecognized character
        i++;
      }
    }
    return tokens;
  }

  static bool _isDigitOrDot(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 48 && code <= 57) || char == '.';
  }
}

enum _TokenType { number, operator }

class _Token {
  final _TokenType type;
  final String symbol;
  final double? value;

  _Token(this.type, this.symbol, [this.value]);

  @override
  String toString() => value != null ? '$value' : symbol;
}

class _Parser {
  final List<_Token> tokens;
  int _pos = 0;

  _Parser(this.tokens);

  _Token? get _current => _pos < tokens.length ? tokens[_pos] : null;

  double parse() {
    final result = _parseAddSub();
    if (_pos < tokens.length) {
      throw FormatException('Unexpected token at position $_pos: ${tokens[_pos]}');
    }
    return result;
  }

  double _parseAddSub() {
    double left = _parseMulDiv();

    while (_current != null && _current!.type == _TokenType.operator) {
      final op = _current!.symbol;
      if (op == '+' || op == '-') {
        _pos++;
        final right = _parseMulDiv();
        if (op == '+') {
          left = left + right;
        } else {
          left = left - right;
        }
      } else {
        break;
      }
    }
    return left;
  }

  double _parseMulDiv() {
    double left = _parseFactor();

    while (_current != null && _current!.type == _TokenType.operator) {
      final op = _current!.symbol;
      if (op == '*' || op == '/' || op == '%') {
        _pos++;
        if (op == '%') {
          // Percentage operator: if followed by operator or end, it acts as left / 100
          left = left / 100.0;
        } else {
          final right = _parseFactor();
          if (op == '*') {
            left = left * right;
          } else {
            if (right == 0) throw FormatException('Division by zero');
            left = left / right;
          }
        }
      } else {
        break;
      }
    }
    return left;
  }

  double _parseFactor() {
    if (_current == null) throw FormatException('Unexpected end of expression');

    // Unary + or -
    if (_current!.type == _TokenType.operator && (_current!.symbol == '+' || _current!.symbol == '-')) {
      final op = _current!.symbol;
      _pos++;
      final factor = _parseFactor();
      return op == '-' ? -factor : factor;
    }

    // Parentheses
    if (_current!.type == _TokenType.operator && _current!.symbol == '(') {
      _pos++; // consume '('
      final val = _parseAddSub();
      if (_current == null || _current!.symbol != ')') {
        throw FormatException('Missing closing parenthesis');
      }
      _pos++; // consume ')'
      
      // Check for trailing % on parenthesized group
      if (_current != null && _current!.symbol == '%') {
        _pos++;
        return val / 100.0;
      }
      return val;
    }

    // Number
    if (_current!.type == _TokenType.number) {
      final val = _current!.value!;
      _pos++;

      // Check for trailing % e.g. 15% -> 0.15
      if (_current != null && _current!.symbol == '%') {
        _pos++;
        return val / 100.0;
      }

      return val;
    }

    throw FormatException('Unexpected token: ${_current!.symbol}');
  }
}
