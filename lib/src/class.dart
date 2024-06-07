import 'callable.dart';
import 'instance.dart';
import 'interpreter.dart';
import 'routine.dart';

/// A Lox class.
final class Class implements Callable {
  /// Create a Lox class.
  Class({
    required this.name,
    required this.superclass,
    required Map<String, Routine> methods,
  }) : _methods = methods;

  /// The name of the class.
  final String name;

  /// The superclass of the class.
  final Class? superclass;
  final Map<String, Routine> _methods;

  /// Returns the method with the given [name] of this class.
  ///
  /// If the class does not implement this method, `null` is returned.
  Routine? findMethod(String name) => _methods[name] ?? superclass?.findMethod(name);

  @override
  int get arity {
    final initializer = findMethod('init');

    if (initializer == null) {
      return 0;
    } else {
      return initializer.arity;
    }
  }

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    final instance = Instance(this);
    final initializer = findMethod('init');

    if (initializer != null) {
      initializer.bind(instance).call(interpreter, arguments);
    }

    return instance;
  }

  @override
  String toString() => name;
}
