import 'errors.dart';
import 'expr.dart';
import 'token.dart';
import 'token_type.dart';

class Interpreter implements ExprVisitor<Object?> {
  Object? interpret(Expr expr) => _evaluate(expr);

  String interpretAndReturnStringRepresentation(Expr expr) {
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
  Object? visitBinaryExpr(Binary expr) {
    final left = _evaluate(expr.left);
    final right = _evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.greater:
        _checkNumberOperands(expr.operator, left, right);
        return (left as double) > (right as double);
      case TokenType.greaterEqual:
        _checkNumberOperands(expr.operator, left, right);
        return (left as double) >= (right as double);
      case TokenType.less:
        _checkNumberOperands(expr.operator, left, right);
        return (left as double) < (right as double);
      case TokenType.lessEqual:
        _checkNumberOperands(expr.operator, left, right);
        return (left as double) <= (right as double);
      case TokenType.bangEqual:
        return left != right; // TODO(mateusfccp): Check if this is valid, as the implementation differs from the Java version from the book
      case TokenType.equalEqual:
        return left == right; // TODO(mateusfccp): Check if this is valid, as the implementation differs from the Java version from the book
      case TokenType.minus:
        _checkNumberOperands(expr.operator, left, right);
        return (left as double) - (right as double);
      case TokenType.plus:
        if ((left is double && right is double) || (left is String && right is String)) {
          return (left as dynamic) + (right as dynamic);
        } else {
          throw RuntimeError(expr.operator, 'Operands must be two numbers or two strings. Got');
        }
      case TokenType.slash:
        _checkNumberOperands(expr.operator, left, right);
        return (left as double) / (right as double);
      case TokenType.star:
        _checkNumberOperands(expr.operator, left, right);
        return (left as double) * (right as double);
      default:
        return null;
    }
  }

  @override
  Object? visitGroupingExpr(Grouping expr) => _evaluate(expr.expression);

  @override
  Object? visitLiteralExpr(Literal expr) => expr.value;

  @override
  Object? visitUnaryExpr(Unary expr) {
    final right = _evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.bang:
        return !_isTruthy(right);
      case TokenType.minus:
        _checkNumberOperand(expr.operator, right);
        return -(right as double);
      default:
        return null;
    }
  }

  Object? _evaluate(Expr expr) => expr.accept(this);

  bool _isTruthy(Object? value) {
    if (value == null) {
      return true;
    } else if (value is bool) {
      return value;
    } else {
      return true;
    }
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