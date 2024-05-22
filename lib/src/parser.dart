import 'package:dlox/src/statement.dart';

import 'error.dart';
import 'expression.dart';
import 'token.dart';
import 'token_type.dart';

final class Parser {
  Parser(
    this._tokens, {
    ErrorHandler? errorHandler,
  }) : _errorHandler = errorHandler;

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
    final statements = <Statement>[];

    while (!_isAtEnd) {
      final declaration = _declaration();

      if (declaration != null) {
        statements.add(declaration);
      }
    }

    return statements;
  }

  bool _match(Set<TokenType> types) {
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
      if (_match({TokenType.varKeyword})) {
        return _variableDeclaration();
      } else {
        return _statement();
      }
    } on ParseError catch (error) {
      _synchronize();
      _errorHandler?.emit(error);
      return null;
    }
  }

  Statement _statement() {
    if (_match({TokenType.printKeyword})) {
      return _printStatement();
    } else if (_match({TokenType.leftBrace})) {
      return BlockStatement(_block());
    } else {
      return _expressionStatement();
    }
  }

  Statement _printStatement() {
    final value = _expression();
    _consume(TokenType.semicolon, "Expect ';' after value.");
    return PrintStatement(value);
  }

  Statement _variableDeclaration() {
    final name = _consume(TokenType.identifier, 'Expect variable name.');

    final Expression? initializer;
    if (_match({TokenType.equal})) {
      initializer = _expression();
    } else {
      initializer = null;
    }

    _consume(TokenType.semicolon, "Expect ';' after variable declaration");
    return VariableStatement(name, initializer);
  }

  Statement _expressionStatement() {
    final expression = _expression();
    _consume(TokenType.semicolon, "Expect ';' after expression");
    return ExpressionStatement(expression);
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
    final expression = _equality();

    if (_match({TokenType.equal})) {
      final equals = _previous;
      final value = _assignment();

      if (expression is VariableExpression) {
        return AssignExpression(expression.name, value);
      }

      _errorHandler?.emit(
        ParseError(equals, "Invalid assignment target."),
      );
    }

    return expression;
  }

  Expression _equality() {
    var expression = _comparison();

    while (_match({TokenType.bangEqual, TokenType.equalEqual})) {
      final operator = _previous;
      final right = _comparison();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _comparison() {
    var expression = _term();

    while (_match({TokenType.greater, TokenType.greaterEqual, TokenType.less, TokenType.lessEqual})) {
      final operator = _previous;
      final right = _term();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _term() {
    var expression = _factor();

    while (_match({TokenType.minus, TokenType.plus})) {
      final operator = _previous;
      final right = _factor();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _factor() {
    var expression = _unary();

    while (_match({TokenType.slash, TokenType.star})) {
      final operator = _previous;
      final right = _unary();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _unary() {
    if (_match({TokenType.bang, TokenType.minus})) {
      final operator = _previous;
      final right = _unary();
      return UnaryExpression(operator, right);
    } else {
      return _primary();
    }
  }

  Expression _primary() {
    if (_match({TokenType.falseKeyword})) {
      return LiteralExpression(false);
    } else if (_match({TokenType.trueKeyword})) {
      return LiteralExpression(true);
    } else if (_match({TokenType.nilKeyword})) {
      return LiteralExpression(null);
    } else if (_match({TokenType.number, TokenType.string})) {
      return LiteralExpression(_previous.literal);
    } else if (_match({TokenType.identifier})) {
      return VariableExpression(_previous);
    } else if (_match({TokenType.leftParen})) {
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
