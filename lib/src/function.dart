import 'callable.dart';
import 'environment.dart';
import 'instance.dart';
import 'interpreter.dart';
import 'return.dart';
import 'statement.dart';

final class Functionn implements Callable {
  Functionn(
    this.declaration,
    this._closure,
    this._initializer,
  );

  final FunctionStatement declaration;
  final Environment _closure;
  final bool _initializer;

  Functionn bind(Instance instance) {
    final environment = Environment(enclosing: _closure);
    environment.define('this', instance);
    return Functionn(
      declaration,
      environment,
      _initializer,
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
      if (_initializer) {
        return _closure.getAt(0, 'this');
      } else {
        return returnValue.value;
      }
    }

    if (_initializer) {
      return _closure.getAt(0, 'this');
    } else {
      return null;
    }
  }

  @override
  String toString() => '<fn ${declaration.name.lexeme}>';
}
