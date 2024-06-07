import 'dart:io';

import 'builtin_functions/clock.dart';
import 'callable.dart';
import 'class.dart';
import 'environment.dart';
import 'error.dart';
import 'expression.dart';
import 'instance.dart';
import 'return.dart';
import 'routine.dart';
import 'routine_type.dart';
import 'statement.dart';
import 'token.dart';

/// A Lox interpreter.
final class Interpreter implements ExpressionVisitor<Object?>, StatementVisitor<void> {
  /// Creates a Lox interpreter.
  Interpreter({ErrorHandler? errorHandler}) : _errorHandler = errorHandler;

  late Environment _environment = globalEnvironment;

  /// The global environment of the program.
  ///
  /// The global environment is independent of each run. That means if you
  /// [interpret] more than on program, these programs will share this
  /// global environment.
  // TODO(mateusfccp): Is this behavior intended?
  final globalEnvironment = Environment() //
    ..define('clock', ClockCallable());

  final _locals = <Expression, int>{};

  final ErrorHandler? _errorHandler;

  /// Interpret a Lox program.
  ///
  /// A Lox program is given by a list of [statements].
  void interpret(List<Statement> statements) {
    try {
      for (final statement in statements) {
        _execute(statement);
      }
    } on LoxError catch (error) {
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
      (TokenType.asterisk, double left, double right) => (left) * (right),
      (TokenType.greater || TokenType.greaterEqual || TokenType.less || TokenType.lessEqual || TokenType.minus || TokenType.slash || TokenType.asterisk, _, _) =>
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
  Object? visitSuperExpression(SuperExpression expression) {
    final distance = _locals[expression];

    if (distance == null) {
      throw RuntimeError(expression.method, "'${expression.method.lexeme}' method has no access to 'super'. Are you sure the class has a superclass?");
    }

    final superclass = _environment.getAt(distance, 'super') as Class; // TODO(mateusfccp): avoid cast
    final object = _environment.getAt(distance - 1, 'this') as Instance; // TODO(mateusfccp): avoid cast
    final method = superclass.findMethod(expression.method.lexeme);

    if (method == null) {
      throw RuntimeError(expression.method, "Undefined property '${expression.method.lexeme}'.");
    } else {
      return method.bind(object);
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

  /// Resolve the given [expression] at [depth].
  void resolve(Expression expression, int depth) => _locals[expression] = depth;

  /// Execute a list of [statements] with an [environment].
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
    final Class? superclass;

    if (statement.superclass case final potentialSuperclass?) {
      if (_evaluate(potentialSuperclass) case final Class evaluatedSuperclass) {
        superclass = evaluatedSuperclass;
      } else {
        throw RuntimeError(
          potentialSuperclass.name,
          'Superclass must be a class',
        );
      }
    } else {
      superclass = null;
    }

    _environment.define(statement.name.lexeme, null);

    if (statement.superclass != null) {
      _environment = Environment(enclosing: _environment);
      _environment.define('super', superclass);
    }

    final methods = <String, Routine>{
      for (final method in statement.methods)
        method.name.lexeme: Routine(
          declaration: method,
          closure: _environment,
          type: method.name.lexeme == 'init' //
              ? RoutineType.initializer
              : RoutineType.method,
        ),
    };

    final class_ = Class(
      name: statement.name.lexeme,
      superclass: superclass,
      methods: methods,
    );

    if (statement.superclass != null) {
      _environment = _environment.enclosing!; // TODO(mateusfccp): Remove this bang
    }

    _environment.assign(statement.name, class_);
  }

  @override
  void visitExpressionStatement(ExpressionStatement statement) => _evaluate(statement.expression);

  @override
  void visitFunctionStatement(FunctionStatement statement) {
    final function = Routine(
      declaration: statement,
      closure: _environment,
      type: RoutineType.function,
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
