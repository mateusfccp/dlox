import 'class.dart';
import 'error.dart';
import 'token.dart';

final class Instance {
  Instance(this._class);

  final Class _class;
  final Map<String, Object?> _fields = {};

  Object? get(Token name) {
    if (_fields.containsKey(name.lexeme)) {
      return _fields[name.lexeme];
    } else if (_class.findMethod(name.lexeme) case final method?) {
      return method.bind(this);
    } else {
      throw RuntimeError(name, "Undefined property '${name.lexeme}'.");
    }
  }

  void set(Token name, Object? value) => _fields[name.lexeme] = value;

  @override
  String toString() => '${_class.name} instance';
}
