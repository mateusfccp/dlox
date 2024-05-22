import 'dart:io';

import 'environment.dart';
import 'error.dart';
import 'expression.dart';
import 'statement.dart';
import 'token.dart';
import 'token_type.dart';

final class Interpreter implements ExpressionVisitor<Object?>, StatementVisitor<void> {
  Interpreter({ErrorHandler? errorHandler}) : _errorHandler = errorHandler;

  Environment _environment = Environment();

  final ErrorHandler? _errorHandler;

  void interpret(List<Statement> statements) {
    try {
      for (final statement in statements) {
        _execute(statement);
      }
    } on DloxError catch (error) {
      _errorHandler?.emit(error);
    }
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
  Object? visitBinaryExpression(BinaryExpression expression) {
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
      case TokenType.plus when left is double && right is double:
        return left + right;
      case TokenType.plus when left is String && right is String:
        return left + right;
      case TokenType.plus:
        throw RuntimeError(expression.operator, 'Operands must be two numbers or two strings. Got');
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
  Object? visitGroupingExpression(GroupingExpression expression) => _evaluate(expression.expression);

  @override
  Object? visitLiteralExpression(LiteralExpression expression) => expression.value;

  @override
  Object? visitUnaryExpression(UnaryExpression expression) {
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

  @override
  Object? visitVariableExpression(VariableExpression expression) => _environment.get(expression.name);

  Object? _evaluate(Expression expression) => expression.accept(this);

  void _execute(Statement statement) => statement.accept(this);

  void _executeBlock(List<Statement> statements, Environment environment) {
    final previous = _environment;

    try {
      _environment = environment;

      for (final statement in statements) {
        _execute(statement);
      }
    } finally {
      _environment = previous;
    }
  }

  @override
  void visitBlockStatement(BlockStatement statement) {
    _executeBlock(statement.statements, Environment(enclosing: _environment));
  }

  @override
  void visitExpressionStatement(ExpressionStatement statement) {
    _evaluate(statement.expression);
  }

  @override
  void visitPrintStatement(PrintStatement statement) {
    final value = _evaluate(statement.expression);
    stdout.writeln(_stringify(value));
  }

  @override
  void visitVariableStatement(VariableStatement statement) {
    final Object? value;

    if (statement.initializer case final initializer?) {
      value = _evaluate(initializer);
    } else {
      value = null;
    }

    _environment.define(statement.name.lexeme, value);
  }

  @override
  Object? visitAssignExpression(AssignExpression expression) {
    final value = _evaluate(expression.value);
    _environment.assign(expression.name, value);
    return value;
  }

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
      throw RuntimeError(operator, 'Operands must be numbers!');
    }
  }
}
