import 'callable.dart';
import 'environment.dart';
import 'interpreter.dart';
import 'return.dart';
import 'statement.dart';

final class Functionn implements Callable {
  Functionn(this.declaration, this.closure);

  final FunctionStatement declaration;
  final Environment closure;

  @override
  int get arity => declaration.parameters.length;

  @override
  Object? call(Interpreter interpreter, List<Object?> arguments) {
    final environment = Environment(enclosing: closure);

    for (int i = 0; i < arguments.length; i++) {
      environment.define(declaration.parameters[i].lexeme, arguments[i]);
    }

    try {
      interpreter.executeBlock(declaration.body, environment);
    } on Return catch (returnValue) {
      return returnValue.value;
    }

    return null;
  }

  @override
  String toString() => '<fn ${declaration.name.lexeme}>';
}
