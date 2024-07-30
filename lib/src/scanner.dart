import 'error.dart';
import 'token.dart';

/// A Lox scanner.
final class Scanner {
  /// Creates a Lox scanner for [source].
  Scanner({
    required String source,
    ErrorHandler? errorHandler,
  })  : _errorHandler = errorHandler,
        _source = source;

  final String _source;
  final ErrorHandler? _errorHandler;
  final _tokens = <Token>[];

  var _start = 0;
  var _current = 0;
  var _line = 1;
  var _column = 0;

  static const _keywords = {
    'and': TokenType.andKeyword,
    'class': TokenType.classKeyword,
    'else': TokenType.elseKeyword,
    'false': TokenType.falseKeyword,
    'for': TokenType.forKeyword,
    'fun': TokenType.funKeyword,
    'if': TokenType.ifKeyword,
    'unless': TokenType.unlessKeyword,
    'nil': TokenType.nilKeyword,
    'or': TokenType.orKeyword,
    'print': TokenType.printKeyword,
    'return': TokenType.returnKeyword,
    'super': TokenType.superKeyword,
    'this': TokenType.thisKeyword,
    'true': TokenType.trueKeyword,
    'var': TokenType.varKeyword,
    'while': TokenType.whileKeyword,
  };

  bool get _isAtEnd => _current >= _source.length;

  /// Scans the source and returns the tokens.
  List<Token> scanTokens() {
    while (!_isAtEnd) {
      _start = _current;
      _scanToken();
    }

    _tokens.add(
      Token(
        type: TokenType.endOfFile,
        lexeme: '',
        literal: null,
        column: _column,
        line: _line,
      ),
    );
    return _tokens;
  }

  void _scanToken() {
    final character = _advance();
    switch (character) {
      case '(':
        return _addToken(TokenType.leftParenthesis);
      case ')':
        return _addToken(TokenType.rightParenthesis);
      case '{':
        return _addToken(TokenType.leftBrace);
      case '}':
        return _addToken(TokenType.rightBrace);
      case ',':
        return _addToken(TokenType.comma);
      case '.':
        return _addToken(TokenType.dot);
      case '-':
        return _addToken(TokenType.minus);
      case '+':
        return _addToken(TokenType.plus);
      case ';':
        return _addToken(TokenType.semicolon);
      case '*':
        return _addToken(TokenType.asterisk);
      case '!':
        return _addToken(_match('=') ? TokenType.bangEqual : TokenType.bang);
      case '=':
        return _addToken(_match('=') ? TokenType.equalEqual : TokenType.equal);
      case '<':
        return _addToken(_match('=') ? TokenType.lessEqual : TokenType.less);
      case '>':
        return _addToken(_match('=') ? TokenType.greaterEqual : TokenType.greater);
      case '/':
        if (_match('/')) {
          while (_peek() != '\n' && !_isAtEnd) {
            _advance();
          }
        } else {
          _addToken(TokenType.slash);
        }
        break;
      case ' ' || '\r' || '\t':
        break;
      case '\n':
        _line++;
        _column = 0;
      case '"':
        return _string();
      default:
        if (_isDigit(character)) {
          _number();
        } else if (_isAlpha(character)) {
          _identifier();
        } else {
          _errorHandler?.emit(
            UnexpectedCharacterError(
              location: ScanLocation(
                offset: _current,
                line: _line,
                column: _column,
              ),
              character: character,
            ),
          );
        }
    }
  }

  void _addToken(TokenType type, [Object? literal]) {
    final text = _source.substring(_start, _current);
    final token = Token(
      type: type,
      lexeme: text,
      literal: literal,
      column: _column,
      line: _line,
    );

    _tokens.add(token);
  }

  String _advance() {
    _column++;
    return _source[_current++];
  }

  bool _match(String expected) {
    if (_isAtEnd || _source[_current] != expected) {
      return false;
    } else {
      _column++;
      _current++;
      return true;
    }
  }

  String _peek() => _isAtEnd ? '\x00' : _source[_current];

  String _peekNext() => _current + 1 >= _source.length ? '\x00' : _source[_current + 1];

  bool _isDigit(String character) {
    assert(character.length == 1);
    return int.tryParse(character) != null;
  }

  bool _isAlpha(String character) {
    assert(character.length == 1);
    return RegExp('[A-Za-z_]').hasMatch(character);
  }

  bool _isAlphanumeric(String character) {
    assert(character.length == 1);
    return RegExp(r'\w').hasMatch(character);
  }

  void _string() {
    // Consume all the characters until we find the closing quotes (")
    while (_peek() != '"' && !_isAtEnd) {
      if (_peek() == '\n') {
        _line++;
        _column = 0;
      }
      _advance();
    }

    // Thrown an error if the content ends before the string is closed
    if (_isAtEnd) {
      _errorHandler?.emit(
        UnterminatedStringError(
          location: ScanLocation(
            offset: _current,
            line: _line,
            column: _column,
          ),
        ),
      );
    } else {
      // Advance to the closing quotes (")
      _advance();

      // Get the content between the quotes
      final text = _source.substring(_start + 1, _current - 1);
      _addToken(TokenType.string, text);
    }
  }

  void _number() {
    // Consume all the digits before the dot or the end
    while (_isDigit(_peek())) {
      _advance();
    }

    // Look for a fractional part
    if (_peek() == '.' && _isDigit(_peekNext())) {
      // Consume the dot (.)
      _advance();

      while (_isDigit(_peek())) {
        _advance();
      }
    }

    final text = _source.substring(_start, _current);
    final value = double.parse(text);
    _addToken(TokenType.number, value);
  }

  void _identifier() {
    while (_isAlphanumeric(_peek())) {
      _advance();
    }

    final text = _source.substring(_start, _current);

    final TokenType tokenType;

    // We treat `unless` as a identifier unless (sic) it comes directly before
    // a left brackets, in which case we treat it as a keyword.
    if (text == '${TokenType.unlessKeyword}' && _peekNext() != '(') {
      tokenType = TokenType.identifier;
    } else {
      tokenType = _keywords[text] ?? TokenType.identifier;
    }

    _addToken(tokenType);
  }
}
