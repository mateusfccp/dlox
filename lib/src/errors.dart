import 'token.dart';

abstract class DloxError extends Error {
  DloxError(this.message);

  final String message;
}

class ScanError extends DloxError {
  ScanError(this.line, String message) : super(message);

  final int line;
}

class ParseError extends DloxError {
  ParseError(this.token, String message) : super(message);

  final Token token;
}

class RuntimeError extends DloxError {
  RuntimeError(this.token, String message) : super(message);

  final Token token;
}
