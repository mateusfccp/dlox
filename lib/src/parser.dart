import 'errors.dart';
import 'expression.dart';
import 'token.dart';
import 'token_type.dart';

final class Parser {
  Parser(this._tokens);

  final List<Token> _tokens;
  int _current = 0;

  Token get _previous => _tokens[_current - 1];
  Token get _peek => _tokens[_current];
  bool get _isAtEnd => _peek.type == TokenType.endOfFile;
  bool get _isNotAtEnd => !_isAtEnd;

  Expression parse() => _expression();

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
      throw ParseError(_peek, message);
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

  Expression _expression() => _equality();

  Expression _equality() {
    var expr = _comparison();

    while (_match({TokenType.bangEqual, TokenType.equalEqual})) {
      final operator = _previous;
      final right = _comparison();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expression _comparison() {
    var expr = _term();

    while (_match({TokenType.greater, TokenType.greaterEqual, TokenType.less, TokenType.lessEqual})) {
      final operator = _previous;
      final right = _term();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expression _term() {
    var expr = _factor();

    while (_match({TokenType.minus, TokenType.plus})) {
      final operator = _previous;
      final right = _factor();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expression _factor() {
    var expr = _unary();

    while (_match({TokenType.slash, TokenType.star})) {
      final operator = _previous;
      final right = _unary();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expression _unary() {
    if (_match({TokenType.bang, TokenType.minus})) {
      final operator = _previous;
      final right = _unary();
      return Unary(operator, right);
    } else {
      return _primary();
    }
  }

  Expression _primary() {
    if (_match({TokenType.falseKeyword})) {
      return Literal(false);
    } else if (_match({TokenType.trueKeyword})) {
      return Literal(true);
    } else if (_match({TokenType.nilKeyword})) {
      return Literal(null);
    } else if (_match({TokenType.number, TokenType.string})) {
      return Literal(_previous.literal);
    } else if (_match({TokenType.leftParen})) {
      final expr = _expression();
      _consume(TokenType.rightParen, "Expect ')' after expression.");
      return Grouping(expr);
    } else {
      throw ParseError(_peek, 'Expect expression.');
    }
  }
}
