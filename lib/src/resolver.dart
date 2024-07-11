import 'dart:collection';

import 'class_type.dart';
import 'error.dart';
import 'expression.dart';
import 'interpreter.dart';
import 'routine_type.dart';
import 'statement.dart';
import 'token.dart';

/// A Lox resolver.
final class Resolver implements ExpressionVisitor<void>, StatementVisitor<void> {
  /// Creates a Lox resolver.
  Resolver({
    required Interpreter interpreter,
    ErrorHandler? errorHandler,
  })  : _errorHandler = errorHandler,
        _interpreter = interpreter;

  final Interpreter _interpreter;
  final _scopes = ListQueue<Map<String, bool>>();
  RoutineType? _currentFunction;
  ClassType? _currentClass;

  final ErrorHandler? _errorHandler;

  /// Resolve the scopes of a Lox program.
  ///
  /// A Lox program is given by a list of [statements].
  void resolve(List<Statement> statements) {
    for (final statement in statements) {
      _resolveStatement(statement);
    }
  }

  void _resolveFunction(FunctionStatement function, RoutineType functionType) {
    final enclosingFunction = _currentFunction;
    _currentFunction = functionType;
    _beginScope();
    for (final parameter in function.parameters) {
      _declare(parameter);
      _define(parameter);
    }
    resolve(function.body);
    _endScope();
    _currentFunction = enclosingFunction;
  }

  void _beginScope() => _scopes.add({});

  void _endScope() => _scopes.removeLast();

  void _declare(Token name) {
    if (_scopes.isNotEmpty) {
      final scope = _scopes.last;

      if (scope.containsKey(name.lexeme)) {
        _errorHandler?.emit(
          VariableAlreadyInScopeError(name),
        );
      }

      scope[name.lexeme] = false;
    }
  }

  void _define(Token name) {
    if (_scopes.isNotEmpty) {
      _scopes.last[name.lexeme] = true;
    }
  }

  void _resolveLocal(Expression expression, Token name) {
    for (int i = _scopes.length - 1; i >= 0; i--) {
      if (_scopes.elementAt(i).containsKey(name.lexeme)) {
        _interpreter.resolve(expression, _scopes.length - 1 - i);
        return;
      }
    }
  }

  @override
  void visitBlockStatement(BlockStatement statement) {
    _beginScope();
    resolve(statement.statements);
    _endScope();
  }

  @override
  void visitClassStatement(ClassStatement statement) {
    final enclosingClass = _currentClass;
    _currentClass = ClassType.class_;

    _declare(statement.name);
    _define(statement.name);

    if (statement.superclass case final superclass?) {
      if (statement.name.lexeme == superclass.name.lexeme) {
        _errorHandler?.emit(
          ClassInheritsFromItselfError(superclass.name),
        );
      }

      _currentClass = ClassType.subclass;

      _resolveExpression(superclass);

      // Begin `super` scope
      _beginScope();
      _scopes.last['super'] = true;
    }

    // Begin `this` scope
    _beginScope();
    _scopes.last['this'] = true;

    for (final method in statement.methods) {
      final functionType = method.name.lexeme == 'init' //
          ? RoutineType.initializer
          : RoutineType.method;

      _resolveFunction(method, functionType);
    }

    // End `this` scope
    _endScope();

    // End `super` scope
    if (statement.superclass != null) {
      _endScope();
    }

    _currentClass = enclosingClass;
  }

  @override
  void visitExpressionStatement(ExpressionStatement statement) => _resolveExpression(statement.expression);

  @override
  void visitFunctionStatement(FunctionStatement statement) {
    _declare(statement.name);
    _define(statement.name);

    _resolveFunction(statement, RoutineType.function);
  }

  @override
  void visitIfStatement(IfStatement statement) {
    _resolveExpression(statement.condition);
    _resolveStatement(statement.thenBranch);
    if (statement.elseBranch case final elseBranch?) _resolveStatement(elseBranch);
  }

  @override
  void visitPrintStatement(PrintStatement statement) => _resolveExpression(statement.expression);

  @override
  void visitReturnStatement(ReturnStatement statement) {
    if (_currentFunction == null) {
      _errorHandler?.emit(
        ReturnUsedOnTopLevelError(statement.keyword),
      );
    }

    if (statement.value case final value?) {
      if (_currentFunction == RoutineType.initializer) {
        _errorHandler?.emit(
          ClassInitializerReturnsValueError(
            token: statement.keyword,
            value: value,
          ),
        );
      }

      _resolveExpression(value);
    }
  }

  @override
  void visitVariableStatement(VariableStatement statement) {
    _declare(statement.name);
    if (statement.initializer case final initializer?) {
      _resolveExpression(initializer);
    }
    _define(statement.name);
  }

  @override
  void visitWhileStatement(WhileStatement statement) {
    _resolveExpression(statement.condition);
    _resolveStatement(statement.body);
  }

  @override
  void visitAssignExpression(AssignExpression expression) {
    _resolveExpression(expression.value);
    _resolveLocal(expression, expression.name);
  }

  @override
  void visitBinaryExpression(BinaryExpression expression) {
    _resolveExpression(expression.left);
    _resolveExpression(expression.right);
  }

  @override
  void visitCallExpression(CallExpression expression) {
    _resolveExpression(expression.callee);

    for (final argument in expression.arguments) {
      _resolveExpression(argument);
    }
  }

  @override
  void visitGetExpression(GetExpression expression) => _resolveExpression(expression.object);

  @override
  void visitGroupingExpression(GroupingExpression expression) => _resolveExpression(expression.expression);

  @override
  void visitLiteralExpression(LiteralExpression expression) {}

  @override
  void visitLogicalExpression(LogicalExpression expression) {
    _resolveExpression(expression.left);
    _resolveExpression(expression.right);
  }

  @override
  void visitSetExpression(SetExpression expression) {
    _resolveExpression(expression.object);
    _resolveExpression(expression.value);
  }

  @override
  void visitSuperExpression(SuperExpression expression) {
    if (_currentClass == null) {
      _errorHandler?.emit(
        SuperUsedOutsideOfClassError(expression.keyword),
      );
    } else if (_currentClass == ClassType.class_) {
      _errorHandler?.emit(
        SuperUsedInAClassWithoutSuperclassError(expression.keyword),
      );
    } else {
      _resolveLocal(expression, expression.keyword);
    }
  }

  @override
  void visitThisExpression(ThisExpression expression) {
    if (_currentClass == null) {
      _errorHandler?.emit(
        ThisUsedOutsideOfClassError(expression.keyword),
      );
    } else {
      _resolveLocal(expression, expression.keyword);
    }
  }

  @override
  void visitUnaryExpression(UnaryExpression expression) => _resolveExpression(expression.right);

  @override
  void visitVariableExpression(VariableExpression expression) {
    if (_scopes.isNotEmpty && _scopes.last[expression.name.lexeme] == false) {
      _errorHandler?.emit(
        VariableInitializerReadsItselfError(expression.name),
      );
    }

    _resolveLocal(expression, expression.name);
  }

  void _resolveStatement(Statement statement) => statement.accept(this);

  void _resolveExpression(Expression expression) => expression.accept(this);
}
