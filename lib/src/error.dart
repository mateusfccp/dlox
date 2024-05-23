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

final class ErrorHandler {
  final _errors = <DloxError>[];
  final _listeners = <void Function()>[];

  bool get hadError => _errors.isNotEmpty;

  DloxError? get lastError => hadError ? _errors[_errors.length - 1] : null;

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void emit(DloxError error) {
    _errors.add(error);
    for (final listener in _listeners) {
      listener.call();
    }
  }
}
