import 'error.dart';
import 'token.dart';

final class Environment {
  Environment({this.enclosing});

  final Environment? enclosing;

  final _values = <String, Object?>{};

  Object? get(Token name) {
    if (_values[name.lexeme] case final value?) {
      return value;
    } else if (enclosing case final enclosing?) {
      return enclosing.get(name);
    } else {
      throw RuntimeError(name, "Undefined variable '${name.lexeme}'.");
    }
  }

  void assign(Token name, Object? value) {
    if (_values.containsKey(name.lexeme)) {
      _values[name.lexeme] = value;
    } else if (enclosing case final enclosing?) {
      enclosing.assign(name, value);
    } else {
      throw RuntimeError(name, "Undefined variable '${name.lexeme}'.");
    }
  }

  void define(String name, Object? value) => _values[name] = value;
}
