import 'callable.dart';
import 'environment.dart';
import 'instance.dart';
import 'interpreter.dart';
import 'return.dart';
import 'routine_type.dart';
import 'statement.dart';

final class Routine implements Callable {
  const Routine({
    required this.declaration,
    required Environment closure,
    required RoutineType type,
  })  : _closure = closure,
        _type = type;

  final FunctionStatement declaration;
  final Environment _closure;
  final RoutineType _type;

  Routine bind(Instance instance) {
    final environment = Environment(enclosing: _closure);
    environment.define('this', instance);
    return Routine(
      declaration: declaration,
      closure: environment,
      type: _type,
    );
  }

  @override
  int get arity => declaration.parameters.length;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    final environment = Environment(enclosing: _closure);

    for (int i = 0; i < arguments.length; i++) {
      environment.define(declaration.parameters[i].lexeme, arguments[i]);
    }

    try {
      interpreter.executeBlock(declaration.body, environment);
    } on Return catch (returnValue) {
      if (_type == RoutineType.initializer) {
        return _closure.getAt(0, 'this');
      } else {
        return returnValue.value;
      }
    }

    if (_type == RoutineType.initializer) {
      return _closure.getAt(0, 'this');
    } else {
      return null;
    }
  }

  @override
  String toString() => '<fn ${declaration.name.lexeme}>';
}
