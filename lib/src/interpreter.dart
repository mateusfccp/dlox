import 'dart:io' as io;

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
  Interpreter({
    ErrorHandler? errorHandler,
    io.IOSink? stdout,
  })  : _errorHandler = errorHandler,
        _stdout = stdout ?? io.stdout;

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
  final io.IOSink _stdout;

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
    final operator = expression.operator;

    return switch ((operator.type, left, right)) {
      (TokenType.bangEqual, _, _) => left != right, // TODO(mateusfccp): Check if this is valid, as the implementation differs from the Java version from the book
      (TokenType.equalEqual, _, _) => left == right, // TODO(mateusfccp): Check if this is valid, as the implementation differs from the Java version from the book
      (TokenType.greater, double left, double right) => left > right,
      (TokenType.greaterEqual, double left, double right) => left >= right,
      (TokenType.less, double left, double right) => left < right,
      (TokenType.lessEqual, double left, double right) => left <= right,
      (TokenType.minus, double left, double right) => left - right,
      (TokenType.plus, double left, double right) => left + right,
      (TokenType.plus, String left, String right) => '$left$right',
      (TokenType.slash, double left, double right) => left / right,
      (TokenType.asterisk, double left, double right) => left * right,
      (TokenType.plus, final left, final right) => throw InvalidOperandsForPlusOperatorError(
          token: operator,
          left: left,
          right: right,
        ),
      (TokenType.greater || TokenType.greaterEqual || TokenType.less || TokenType.lessEqual || TokenType.minus || TokenType.slash || TokenType.asterisk, _, _) =>
        throw InvalidOperandsForNumericBinaryOperatorsError(
          token: operator,
          left: left,
          right: right,
        ),
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
      throw NonRoutineCalledError(
        token: expression.parenthesis,
        callee: callee,
      );
    } else if (arguments.length != callee.arity) {
      throw ArityError(
        token: expression.parenthesis,
        arity: callee.arity,
        argumentsCount: arguments.length,
      );
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
      throw NonInstanceTriedToGetFieldError(
        token: expression.name,
        caller: object,
      );
    }
  }

  @override
  Object? visitGroupingExpression(GroupingExpression expression) => _evaluate(expression.expression);

  @override
  Object? visitLiteralExpression(LiteralExpression expression) => expression.value;

  @override
  Object? visitLogicalExpression(LogicalExpression expression) {
    final left = _evaluate(expression.left);

    return switch ((expression.operator.type, _isTruthy(left))) {
      (TokenType.andKeyword, false) || //
      (TokenType.orKeyword, true) =>
        left,
      _ => _evaluate(expression.right),
    };
  }

  @override
  Object? visitSetExpression(SetExpression expression) {
    final object = _evaluate(expression.object);

    if (object is Instance) {
      final value = _evaluate(expression.value);

      object.set(expression.name, value);

      return value;
    } else {
      throw NonInstanceTriedToSetFieldError(
        token: expression.name,
        caller: object,
      );
    }
  }

  @override
  Object? visitSuperExpression(SuperExpression expression) {
    final distance = _locals[expression]!; // This is suposedly guaranteed to be non-null because the resolver already checks for super calls in class that have not a supertype
    final superclass = _environment.getAt(distance, 'super') as Class;
    final object = _environment.getAt(distance - 1, 'this') as Instance;
    final method = superclass.findMethod(expression.method.lexeme);

    if (method == null) {
      throw UndefinedPropertyError(expression.method);
    } else {
      return method.bind(object);
    }
  }

  @override
  Object? visitThisExpression(ThisExpression expression) => _lookUpVariable(expression.keyword, expression);

  @override
  Object? visitUnaryExpression(UnaryExpression expression) {
    final right = _evaluate(expression.right);
    final operator = expression.operator;

    return switch (operator.type) {
      TokenType.bang => !_isTruthy(right),
      TokenType.minus when right is double => -right,
      TokenType.minus => throw InvalidOperandForUnaryMinusOperatorError(
          token: operator,
          right: right,
        ),
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
        throw ClassInheritsFromANonClassError(potentialSuperclass.name);
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
    _stdout.writeln(_stringify(value));
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
