import 'package:dlox/src/callable.dart';
import 'package:dlox/src/interpreter.dart';

final class ClockCallable implements Callable {
  @override
  int get arity => 0;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) =>
      DateTime.now().microsecondsSinceEpoch / 1e+6;

  @override
  String toString() => '<native function>';
}
