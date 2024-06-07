import 'dart:collection';

import 'token.dart';

/// A Lox error.
sealed class LoxError extends Error {
  LoxError(this.message);

  final String message;
}

/// An error that happened while the program was being scanend.
final class ScanError extends LoxError {
  ScanError(this.line, super.message);

  final int line;
}

/// An error that happened while the program was being parsed.
final class ParseError extends LoxError {
  ParseError(this.token, super.message);

  final Token token;
}

/// An error that happened while the program was being run.
final class RuntimeError extends LoxError {
  RuntimeError(this.token, super.message);

  final Token token;
}

/// An Lox error handler.
final class ErrorHandler {
  final _errors = <LoxError>[];
  final _listeners = <void Function()>[];

  /// The errors that were emitted by the handler.
  UnmodifiableListView<LoxError> get errors => UnmodifiableListView(_errors);

  /// Whether at least one error was emitted.
  bool get hasError => _errors.isNotEmpty;

  /// The last emitted error.
  ///
  /// If no error was emitted, `null` is returned.
  LoxError? get lastError => hasError ? _errors[_errors.length - 1] : null;

  /// Adds a [listener] to the handler.
  ///
  /// A listener will be called whenever an erro is emitted. The emmited error
  /// is passed to the listener.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Removes [listener] from the handler.
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Emits an [error].
  ///
  /// The listeners will be notified of the error.
  void emit(LoxError error) {
    _errors.add(error);
    for (final listener in _listeners) {
      listener.call();
    }
  }
}
