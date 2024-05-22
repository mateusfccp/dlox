import 'package:meta/meta.dart';

import 'token_type.dart';

@immutable final class Token {
  const Token({
    required this.type,
    required this.lexeme,
    required this.line,
    this.literal,
  });

  final TokenType type;
  final String lexeme;
  final int line;
  final Object? literal;

  @override
  String toString() => '$type $lexeme $literal';
}