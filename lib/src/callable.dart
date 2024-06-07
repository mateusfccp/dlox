import 'interpreter.dart';

/// A Lox Callable.
abstract interface class Callable {
  /// The arity of the callable.
  int get arity;

  /// The method to be executed when the callable is called.
  Object? call(Interpreter interpreter, List<Object?> arguments);
}
