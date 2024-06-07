import 'error.dart';
import 'expression.dart';
import 'routine_type.dart';
import 'statement.dart';
import 'token.dart';
import 'token_type.dart';

final class Parser {
  Parser({
    required List<Token> tokens,
    ErrorHandler? errorHandler,
  })  : _errorHandler = errorHandler,
        _tokens = tokens;

  final List<Token> _tokens;
  final ErrorHandler? _errorHandler;

  int _current = 0;

  ParseError _error(Token token, String message) {
    final error = ParseError(token, message);
    _errorHandler?.emit(error);
    return error;
  }

  Token get _previous => _tokens[_current - 1];

  Token get _peek => _tokens[_current];

  bool get _isAtEnd => _peek.type == TokenType.endOfFile;

  bool get _isNotAtEnd => !_isAtEnd;

  List<Statement> parse() {
    return [
      for (; !_isAtEnd;)
        if (_declaration() case final declaration?) declaration,
    ];
  }

  bool _match(TokenType type1, [TokenType? type2, TokenType? type3, TokenType? type4]) {
    final types = [type1, type2, type3, type4].nonNulls;

    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }

    return false;
  }

  bool _check(TokenType type) => _isNotAtEnd && _peek.type == type;

  Token _advance() {
    if (_isNotAtEnd) _current++;
    return _previous;
  }

  Token _consume(TokenType type, String message) {
    if (_check(type)) {
      return _advance();
    } else {
      throw _error(_peek, message);
    }
  }

  void _synchronize() {
    _advance();
    while (_isNotAtEnd) {
      if (_previous.type == TokenType.semicolon) {
        return;
      } else {
        switch (_peek.type) {
          case TokenType.classKeyword:
          case TokenType.forKeyword:
          case TokenType.funKeyword:
          case TokenType.ifKeyword:
          case TokenType.printKeyword:
          case TokenType.returnKeyword:
          case TokenType.varKeyword:
          case TokenType.whileKeyword:
            return;
          default:
            _advance();
        }
      }
    }
  }

  Expression _expression() => _assignment();

  Statement? _declaration() {
    try {
      if (_match(TokenType.classKeyword)) {
        return _class();
      } else if (_match(TokenType.funKeyword)) {
        return _function(RoutineType.function);
      } else if (_match(TokenType.varKeyword)) {
        return _variableDeclaration();
      } else {
        return _statement();
      }
    } on ParseError {
      _synchronize();
      return null;
    }
  }

  Statement _statement() {
    if (_match(TokenType.forKeyword)) {
      return _forStatement();
    } else if (_match(TokenType.ifKeyword)) {
      return _ifStatement();
    } else if (_match(TokenType.printKeyword)) {
      return _printStatement();
    } else if (_match(TokenType.returnKeyword)) {
      return _returnStatement();
    } else if (_match(TokenType.whileKeyword)) {
      return _whileStatement();
    } else if (_match(TokenType.leftBrace)) {
      return BlockStatement(_block());
    } else {
      return _expressionStatement();
    }
  }

  Statement _class() {
    final name = _consume(TokenType.identifier, 'Expect class name.');
    final VariableExpression? superclass;

    if (_match(TokenType.less)) {
      _consume(TokenType.identifier, 'Expect superclas name.');
      superclass = VariableExpression(_previous);
    } else {
      superclass = null;
    }

    _consume(TokenType.leftBrace, "Expect '{' after class name.");

    final methods = <FunctionStatement>[];

    while (!_check(TokenType.rightBrace) && !_isAtEnd) {
      methods.add(_function(RoutineType.method));
    }

    _consume(TokenType.rightBrace, "Expect '}' after class body.");
    return ClassStatement(
      name,
      superclass,
      methods,
    );
  }

  Statement _forStatement() {
    _consume(TokenType.leftParen, "Expect '(' after 'for'.");

    final Statement? initializer;
    if (_match(TokenType.semicolon)) {
      initializer = null;
    } else if (_match(TokenType.varKeyword)) {
      initializer = _variableDeclaration();
    } else {
      initializer = _expressionStatement();
    }

    final Expression? condition;
    if (_check(TokenType.semicolon)) {
      condition = null;
    } else {
      condition = _expression();
    }
    _consume(TokenType.semicolon, "Expect ';' after loop condition.");

    final Expression? increment;
    if (_check(TokenType.rightParen)) {
      increment = null;
    } else {
      increment = _expression();
    }

    _consume(TokenType.rightParen, "Expect ')' after for clauses.");

    final body = _statement();

    return BlockStatement([
      if (initializer != null) initializer,
      WhileStatement(
        condition ?? LiteralExpression(true),
        BlockStatement([
          body,
          if (increment != null) ExpressionStatement(increment),
        ]),
      ),
    ]);
  }

  Statement _ifStatement() {
    _consume(TokenType.leftParen, "Expect '(' after 'if'.");
    final condition = _expression();
    _consume(TokenType.rightParen, "Expect ')' after if condition.");

    final thenBranch = _statement();

    final Statement? elseBranch;

    if (_match(TokenType.elseKeyword)) {
      elseBranch = _statement();
    } else {
      elseBranch = null;
    }

    return IfStatement(condition, thenBranch, elseBranch);
  }

  Statement _printStatement() {
    final value = _expression();
    _consume(TokenType.semicolon, "Expect ';' after value.");
    return PrintStatement(value);
  }

  Statement _returnStatement() {
    final keyword = _previous;

    final Expression? value;
    if (_check(TokenType.semicolon)) {
      value = null;
    } else {
      value = _expression();
    }

    _consume(TokenType.semicolon, "Expect ';' after return value.");

    return ReturnStatement(keyword, value);
  }

  Statement _variableDeclaration() {
    final name = _consume(TokenType.identifier, 'Expect variable name.');

    final Expression? initializer;
    if (_match(TokenType.equal)) {
      initializer = _expression();
    } else {
      initializer = null;
    }

    _consume(TokenType.semicolon, "Expect ';' after variable declaration");
    return VariableStatement(name, initializer);
  }

  Statement _whileStatement() {
    _consume(TokenType.leftParen, "Expect '(' after 'while'.");
    final condition = _expression();
    _consume(TokenType.rightParen, "Expect ')' after while condition.");

    return WhileStatement(condition, _statement());
  }

  Statement _expressionStatement() {
    final expression = _expression();
    _consume(TokenType.semicolon, "Expect ';' after expression");
    return ExpressionStatement(expression);
  }

  FunctionStatement _function(RoutineType functionType) {
    final name = _consume(TokenType.identifier, 'Expect $functionType name.');
    final parameters = <Token>[];
    _consume(TokenType.leftParen, '');

    if (!_check(TokenType.rightParen)) {
      do {
        if (parameters.length >= 255) {
          _errorHandler?.emit(
            ParseError(_peek, "Can't have more than 255 parameters."),
          );
        }

        parameters.add(
          _consume(TokenType.identifier, 'Expect parameter name.'),
        );
      } while (_match(TokenType.comma));
    }

    _consume(TokenType.rightParen, '');
    _consume(TokenType.leftBrace, "Expect '{' before $functionType body.");

    return FunctionStatement(name, parameters, _block());
  }

  List<Statement> _block() {
    final statements = <Statement>[];

    while (!_check(TokenType.rightBrace) && !_isAtEnd) {
      final declaration = _declaration();

      if (declaration != null) {
        statements.add(declaration);
      }
    }

    _consume(TokenType.rightBrace, "Expect '}' after block.");
    return statements;
  }

  Expression _assignment() {
    final expression = _or();

    if (_match(TokenType.equal)) {
      final equals = _previous;
      final value = _assignment();

      if (expression is VariableExpression) {
        return AssignExpression(expression.name, value);
      } else if (expression is GetExpression) {
        return SetExpression(expression.object, expression.name, value);
      } else {
        _errorHandler?.emit(
          ParseError(equals, "Invalid assignment target."),
        );
      }
    }

    return expression;
  }

  Expression _or() {
    var expression = _and();

    while (_match(TokenType.orKeyword)) {
      expression = LogicalExpression(
        expression,
        _previous,
        _equality(),
      );
    }

    return expression;
  }

  Expression _and() {
    var expression = _equality();

    while (_match(TokenType.andKeyword)) {
      expression = LogicalExpression(
        expression,
        _previous,
        _equality(),
      );
    }

    return expression;
  }

  Expression _equality() {
    var expression = _comparison();

    while (_match(TokenType.bangEqual, TokenType.equalEqual)) {
      final operator = _previous;
      final right = _comparison();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _comparison() {
    var expression = _term();

    while (_match(TokenType.greater, TokenType.greaterEqual, TokenType.less, TokenType.lessEqual)) {
      final operator = _previous;
      final right = _term();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _term() {
    var expression = _factor();

    while (_match(TokenType.minus, TokenType.plus)) {
      final operator = _previous;
      final right = _factor();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _factor() {
    var expression = _unary();

    while (_match(TokenType.slash, TokenType.star)) {
      final operator = _previous;
      final right = _unary();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _unary() {
    if (_match(TokenType.bang, TokenType.minus)) {
      final operator = _previous;
      final right = _unary();
      return UnaryExpression(operator, right);
    } else {
      return _call();
    }
  }

  Expression _finishCall(Expression callee) {
    final arguments = <Expression>[];

    if (!_check(TokenType.rightParen)) {
      do {
        if (arguments.length >= 255) {
          _errorHandler?.emit(
            ParseError(_peek, "Can't have more than 255 arguments"),
          );
        }
        arguments.add(_expression());
      } while (_match(TokenType.comma));
    }

    final parenthesis = _consume(TokenType.rightParen, "Expect ')' after arguments.");
    return CallExpression(callee, parenthesis, arguments);
  }

  Expression _call() {
    var expression = _primary();

    while (true) {
      if (_match(TokenType.leftParen)) {
        expression = _finishCall(expression);
      } else if (_match(TokenType.dot)) {
        final name = _consume(TokenType.identifier, "Expect property name after '.'.");
        expression = GetExpression(expression, name);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression _primary() {
    if (_match(TokenType.falseKeyword)) {
      return LiteralExpression(false);
    } else if (_match(TokenType.trueKeyword)) {
      return LiteralExpression(true);
    } else if (_match(TokenType.nilKeyword)) {
      return LiteralExpression(null);
    } else if (_match(TokenType.number, TokenType.string)) {
      return LiteralExpression(_previous.literal);
    } else if (_match(TokenType.superKeyword)) {
      final keyword = _previous;
      _consume(TokenType.dot, "Expect '.' after super.");

      final method = _consume(TokenType.identifier, 'Expect superclass method name.');

      return SuperExpression(keyword, method);
    } else if (_match(TokenType.thisKeyword)) {
      return ThisExpression(_previous);
    } else if (_match(TokenType.identifier)) {
      return VariableExpression(_previous);
    } else if (_match(TokenType.leftParen)) {
      final expression = _expression();
      _consume(TokenType.rightParen, "Expect ')' after expression.");
      return GroupingExpression(expression);
    } else {
      final error = ParseError(_peek, 'Expect expression.');
      _errorHandler?.emit(error);
      throw error;
    }
  }
}
