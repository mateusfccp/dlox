import 'errors.dart';
import 'expression.dart';
import 'token.dart';
import 'token_type.dart';

final class Interpreter implements ExpressionVisitor<Object?> {
  Object? interpret(Expression expression) => _evaluate(expression);

  String interpretAndReturnStringRepresentation(Expression expr) {
    final value = _evaluate(expr);
    return _stringify(value);
  }

  String _stringify(Object? value) {
    if (value == null) {
      return 'nil';
    } else if (value is double) {
      final text = value.toString();
      if (text.endsWith('.0')) {
        return text.split('.').first;
      } else {
        return text;
      }
    } else {
      return value.toString();
    }
  }

  @override
  Object? visitBinaryExpression(Binary expression) {
    final left = _evaluate(expression.left);
    final right = _evaluate(expression.right);

    switch (expression.operator.type) {
      case TokenType.greater:
        _checkNumberOperands(expression.operator, left, right);
        return (left as double) > (right as double);
      case TokenType.greaterEqual:
        _checkNumberOperands(expression.operator, left, right);
        return (left as double) >= (right as double);
      case TokenType.less:
        _checkNumberOperands(expression.operator, left, right);
        return (left as double) < (right as double);
      case TokenType.lessEqual:
        _checkNumberOperands(expression.operator, left, right);
        return (left as double) <= (right as double);
      case TokenType.bangEqual:
        return left != right; // TODO(mateusfccp): Check if this is valid, as the implementation differs from the Java version from the book
      case TokenType.equalEqual:
        return left == right; // TODO(mateusfccp): Check if this is valid, as the implementation differs from the Java version from the book
      case TokenType.minus:
        _checkNumberOperands(expression.operator, left, right);
        return (left as double) - (right as double);
      case TokenType.plus:
        if ((left is double && right is double) || (left is String && right is String)) {
          return (left as dynamic) + (right as dynamic);
        } else {
          throw RuntimeError(expression.operator, 'Operands must be two numbers or two strings. Got');
        }
      case TokenType.slash:
        _checkNumberOperands(expression.operator, left, right);
        return (left as double) / (right as double);
      case TokenType.star:
        _checkNumberOperands(expression.operator, left, right);
        return (left as double) * (right as double);
      default:
        return null;
    }
  }

  @override
  Object? visitGroupingExpression(Grouping expression) => _evaluate(expression.expression);

  @override
  Object? visitLiteralExpression(Literal expression) => expression.value;

  @override
  Object? visitUnaryExpression(Unary expression) {
    final right = _evaluate(expression.right);

    switch (expression.operator.type) {
      case TokenType.bang:
        return !_isTruthy(right);
      case TokenType.minus:
        _checkNumberOperand(expression.operator, right);
        return -(right as double);
      default:
        return null;
    }
  }

  Object? _evaluate(Expression expression) => expression.accept(this);

  bool _isTruthy(Object? value) {
    return switch (value) {
      bool() => value,
      Object() || null => true,
    };
  }

  void _checkNumberOperand(Token operator, Object? operand) {
    if (operand is! double) {
      throw RuntimeError(operator, 'Operand must be a number!');
    }
  }

  void _checkNumberOperands(Token operator, Object? left, Object? right) {
    if (left is! double || right is! double) {
      throw RuntimeError(operator, 'Operands must be a number!');
    }
  }
}
