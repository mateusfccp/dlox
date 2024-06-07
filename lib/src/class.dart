import 'callable.dart';
import 'function.dart';
import 'instance.dart';
import 'interpreter.dart';

final class Class implements Callable {
  Class(
    this.name,
    this.superclass,
    this._methods,
  );

  final String name;
  final Class? superclass;
  final Map<String, Functionn> _methods;

  Functionn? findMethod(String name) => _methods[name] ?? superclass?.findMethod(name);

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
