import 'dart:io';

import 'builtin_functions/clock.dart';
import 'callable.dart';
import 'class.dart';
import 'environment.dart';
import 'error.dart';
import 'expression.dart';
import 'function.dart';
import 'instance.dart';
import 'return.dart';
import 'statement.dart';
import 'token.dart';
import 'token_type.dart';

final class Interpreter implements ExpressionVisitor<Object?>, StatementVisitor<void> {
  Interpreter({ErrorHandler? errorHandler}) : _errorHandler = errorHandler;

  late Environment _environment = globalEnvironment;

  final globalEnvironment = Environment() //
    ..define('clock', ClockCallable());

  final _locals = <Expression, int>{};

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

    return switch ((expression.operator.type, left, right)) {
      (TokenType.greater, double left, double right) => left > right,
      (TokenType.greaterEqual, double left, double right) => left >= right,
      (TokenType.less, double left, double right) => left < right,
      (TokenType.lessEqual, double left, double right) => left <= right,
      (TokenType.bangEqual, _, _) => left != right, // TODO(mateusfccp): Check if this is valid, as the implementation differs from the Java version from the book
      (TokenType.equalEqual, _, _) => left == right, // TODO(mateusfccp): Check if this is valid, as the implementation differs from the Java version from the book
      (TokenType.minus, double left, double right) => (left) - (right),
      (TokenType.plus, double left, double right) => left + right,
      (TokenType.plus, String left, String right) => left + right,
      (TokenType.plus, _, _) => throw RuntimeError(expression.operator, 'Operands must be two numbers or two strings. Got'),
      (TokenType.slash, double left, double right) => (left) / (right),
      (TokenType.star, double left, double right) => (left) * (right),
      (TokenType.greater || TokenType.greaterEqual || TokenType.less || TokenType.lessEqual || TokenType.minus || TokenType.slash || TokenType.star, _, _) =>
        throw RuntimeError(expression.operator, 'Operands must be numbers!'),
      _ => null,
    };
  }

  @override
  Object? visitCallExpression(CallExpression expression) {
    final callee = _evaluate(expression.callee);

    final arguments = [
      for (final argument in expression.arguments) _evaluate(argument),
    ];

    if (callee is! Callable) {
      throw RuntimeError(expression.parenthesis, 'Can only call functions and classes.');
    } else if (arguments.length != callee.arity) {
      throw RuntimeError(expression.parenthesis, 'Expected ${callee.arity} arguments but got ${arguments.length}.');
    } else {
      return callee.call(this, arguments);
    }
  }

  @override
  Object? visitGetExpression(GetExpression expression) {
    final object = _evaluate(expression.object);

    if (object is Instance) {
      return object.get(expression.name);
    } else {
      throw RuntimeError(expression.name, 'Only instances have properties. Got a ${object.runtimeType}.');
    }
  }

  @override
  Object? visitGroupingExpression(GroupingExpression expression) => _evaluate(expression.expression);

  @override
  Object? visitLiteralExpression(LiteralExpression expression) => expression.value;

  @override
  Object? visitLogicalExpression(LogicalExpression expression) {
    final left = _evaluate(expression.left);

    if ((expression.operator.type == TokenType.andKeyword && _isTruthy(left)) || //
        (expression.operator.type == TokenType.orKeyword && !_isTruthy(left))) return left;

    return _evaluate(expression.right);
  }

  @override
  Object? visitSetExpression(SetExpression expression) {
    final object = _evaluate(expression.object);

    if (object is Instance) {
      final value = _evaluate(expression.value);

      object.set(expression.name, value);

      return value;
    } else {
      throw RuntimeError(expression.name, 'Only instances have fields. Got a ${object.runtimeType}.');
    }
  }

  @override
  Object? visitThisExpression(ThisExpression expression) => _lookUpVariable(expression.keyword, expression);

  @override
  Object? visitUnaryExpression(UnaryExpression expression) {
    final right = _evaluate(expression.right);

    return switch (expression.operator.type) {
      TokenType.bang => !_isTruthy(right),
      TokenType.minus when right is double => -right,
      TokenType.minus => throw RuntimeError(expression.operator, 'Operand must be a number!'),
      _ => null,
    };
  }

  @override
  Object? visitVariableExpression(VariableExpression expression) => _lookUpVariable(expression.name, expression);

  Object? _lookUpVariable(Token name, Expression expression) {
    final distance = _locals[expression];

    if (distance == null) {
      return globalEnvironment.get(name);
    } else {
      return _environment.getAt(distance, name.lexeme);
    }
  }

  Object? _evaluate(Expression expression) => expression.accept(this);

  void _execute(Statement statement) => statement.accept(this);

  void resolve(Expression expression, int depth) {
    _locals[expression] = depth;
  }

  void executeBlock(List<Statement> statements, Environment environment) {
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
    executeBlock(
      statement.statements,
      Environment(enclosing: _environment),
    );
  }

  @override
  void visitClassStatement(ClassStatement statement) {
    _environment.define(statement.name.lexeme, null);

    final methods = <String, Functionn>{
      for (final method in statement.methods)
        method.name.lexeme: Functionn(
          method,
          _environment,
          method.name.lexeme == 'init',
        ),
    };

    final class_ = Class(
      statement.name.lexeme,
      methods,
    );

    _environment.assign(statement.name, class_);
  }

  @override
  void visitExpressionStatement(ExpressionStatement statement) => _evaluate(statement.expression);

  @override
  void visitFunctionStatement(FunctionStatement statement) {
    final function = Functionn(
      statement,
      _environment,
      false,
    );
    _environment.define(statement.name.lexeme, function);
  }

  @override
  void visitIfStatement(IfStatement statement) {
    final evaluatedCondition = _evaluate(statement.condition);

    if (_isTruthy(evaluatedCondition)) {
      _execute(statement.thenBranch);
    } else if (statement.elseBranch case final elseBranch?) {
      _execute(elseBranch);
    }
  }

  @override
  void visitPrintStatement(PrintStatement statement) {
    final value = _evaluate(statement.expression);
    stdout.writeln(_stringify(value));
  }

  @override
  void visitReturnStatement(ReturnStatement statement) {
    final value = switch (statement.value) {
      Expression value => _evaluate(value),
      null => null,
    };

    throw Return(value);
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
  void visitWhileStatement(WhileStatement statement) {
    while (_isTruthy(_evaluate(statement.condition))) {
      _execute(statement.body);
    }
  }

  @override
  Object? visitAssignExpression(AssignExpression expression) {
    final value = _evaluate(expression.value);
    final distance = _locals[expression];

    if (distance == null) {
      globalEnvironment.assign(expression.name, value);
    } else {
      _environment.assignAt(distance, expression.name, value);
    }

    return value;
  }

  bool _isTruthy(Object? value) {
    return switch (value) {
      bool() => value,
      Object() => true,
      null => false,
    };
  }
}
