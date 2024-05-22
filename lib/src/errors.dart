import 'token.dart';

sealed class DloxError extends Error {
  DloxError(this.message);

  final String message;
}

final class ScanError extends DloxError {
  ScanError(this.line, super.message);

  final int line;
}

final class ParseError extends DloxError {
  ParseError(this.token, super.message);

  final Token token;
}

final class RuntimeError extends DloxError {
  RuntimeError(this.token, super.message);

  final Token token;
}
