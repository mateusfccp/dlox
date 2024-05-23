import 'interpreter.dart';

abstract interface class Callable {
  int get arity;

  Object? call(Interpreter interpreter, List<Object?> arguments);
}
