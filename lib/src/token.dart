import 'package:meta/meta.dart';

/// A Lox program token.
@immutable
final class Token {
  /// Creates a Lox program token.
  const Token({
    required this.type,
    required this.lexeme,
    required this.line,
    required this.column,
    this.literal,
  });

  /// The type of the token.
  final TokenType type;

  /// The string representation of the token.
  final String lexeme;

  /// The line in which the token was scanned.
  final int line;

  /// The column in which the token was scanned.
  final int column;

  /// The literal represented by the token.
  ///
  /// If the token does not represent any literal, this will be `null`.
  final Object? literal;

  @override
  String toString() => '$type $lexeme $literal';
}

/// The type of a token.
enum TokenType {
  /// The left parenthesis token (`(`).
  leftParenthesis,

  /// The right parenthesis token (`)`).
  rightParenthesis,

  /// The left brace token (`{`).
  leftBrace,

  /// The right brace token (`}`).
  rightBrace,

  /// The comma token (`,`).
  comma,

  /// The dot token (`.`).
  dot,

  /// The minus sign token (`-`).
  minus,

  /// The plus sign token (`+`).
  plus,

  /// The semicolon token (`;`).
  semicolon,

  /// The slash token (`/`).
  slash,

  /// The asterisk token (`*`).
  asterisk,

  // The bang token (`!`).
  bang,

  /// The bang-equal token (`!=`).
  bangEqual,

  /// The equal token (`=`).
  equal,

  /// The equal-equal token (`==`).
  equalEqual,

  /// The greater-than token (`>`).
  greater,

  /// The greater-than-or-equal-to token (`>=`).
  greaterEqual,

  /// The less-than token (`<`).
  less,

  /// The less-than-or-equal-to token (`<=`).
  lessEqual,

  /// The identifier token.
  identifier,

  /// The string literal token (`"string"`).
  string,

  /// The number literal token (`0123456789`).
  number,

  /// The `and` keyword token (`and`).
  andKeyword,

  /// The `class` keyword token (`class`).
  classKeyword,

  /// The `else` keyword token.
  elseKeyword,

  /// The `false` keyword token.
  falseKeyword,

  /// The `fun` keyword token.
  funKeyword,

  /// The `for` keyword token.
  forKeyword,

  /// The `if` keyword token.
  ifKeyword,

  /// The `nil` keyword token.
  nilKeyword,

  /// The `or` keyword token.
  orKeyword,

  /// The `print` keyword token.
  printKeyword,

  /// The `return` keyword token.
  returnKeyword,

  /// The `super` keyword token.
  superKeyword,

  /// The `this` keyword token.
  thisKeyword,

  /// The `true` keyword token.
  trueKeyword,

  /// The `var` keyword token.
  varKeyword,

  /// The `while` keyword token.
  whileKeyword,

  /// The end-of-file token.
  endOfFile;

  @override
  String toString() {
    return switch (this) {
      leftParenthesis => '(',
      rightParenthesis => ')',
      leftBrace => '{',
      rightBrace => '}',
      comma => ',',
      dot => '.',
      minus => '-',
      plus => '+',
      semicolon => ';',
      slash => '/',
      asterisk => '*',
      bang => '!',
      bangEqual => '!=',
      equal => '=',
      equalEqual => '!=',
      greater => '>',
      greaterEqual => '>=',
      less => '<',
      lessEqual => '<=',
      identifier => 'identifier',
      string => 'string',
      number => 'number literal',
      andKeyword => 'and',
      classKeyword => 'class',
      elseKeyword => 'else',
      falseKeyword => 'false',
      funKeyword => 'fun',
      forKeyword => 'for',
      ifKeyword => 'if',
      nilKeyword => 'nil',
      orKeyword => 'or',
      printKeyword => 'print',
      returnKeyword => 'return',
      superKeyword => 'super',
      thisKeyword => 'this',
      trueKeyword => 'true',
      varKeyword => 'var',
      whileKeyword => 'while',
      endOfFile => 'EOF',
    };
  }
}
