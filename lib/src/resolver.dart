import 'dart:collection';

import 'class_type.dart';
import 'error.dart';
import 'expression.dart';
import 'function_type.dart';
import 'interpreter.dart';
import 'statement.dart';
import 'token.dart';

final class Resolver implements ExpressionVisitor<void>, StatementVisitor<void> {
  Resolver(
    this._interpreter, {
    ErrorHandler? errorHandler,
  }) : _errorHandler = errorHandler;

  final Interpreter _interpreter;
  final _scopes = ListQueue<Map<String, bool>>();
  FunctionType? _currentFunction;
  ClassType? _currentClass;

  final ErrorHandler? _errorHandler;

  void resolve(List<Statement> statements) {
    for (final statement in statements) {
      _resolveStatement(statement);
    }
  }

  void _resolveFunction(FunctionStatement function, FunctionType functionType) {
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
          ParseError(name, "There's already a variable with this name in this scope."), // TODO(mateusfccp); again, see if we should have a ResolveError
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
          ParseError(superclass.name, "A class can't inherit from itself."), // TODO(mateusfccp): resolve error
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
          ? FunctionType.initializer
          : FunctionType.method;

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

    _resolveFunction(statement, FunctionType.function);
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
        ParseError(statement.keyword, "Can't return from top-level code."), // TODO(mateusfccp): ResolveError
      );
    }

    if (statement.value case final value?) {
      if (_currentFunction == FunctionType.initializer) {
        _errorHandler?.emit(
          ParseError(
            statement.keyword,
            "Can't return a value form an initializer.",
          ), // TODO(mateusfccp): Resolve error daba daba
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
        ParseError(
          expression.keyword,
          "Can't use 'super' outside of a class.",
        ),
      );
    } else if (_currentClass == ClassType.class_) {
      _errorHandler?.emit(
        ParseError(
          expression.keyword,
          "Can't use 'super' in a class with no superclass.",
        ),
      );
    } else {
      _resolveLocal(expression, expression.keyword);
    }
  }

  @override
  void visitThisExpression(ThisExpression expression) {
    if (_currentClass == null) {
      _errorHandler?.emit(
        ParseError(
          expression.keyword,
          "Can't use 'this' outside of a class.",
        ),
      ); // TODO(mateusfccp) Resolver error
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
        ParseError(expression.name, "Can't read local variable in its own initializer."), // TOOD(mateusfccp): Provide resolving error?
      );
    }

    _resolveLocal(expression, expression.name);
  }

  void _resolveStatement(Statement statement) => statement.accept(this);

  void _resolveExpression(Expression expression) => expression.accept(this);
}
