import 'class.dart';
import 'error.dart';
import 'token.dart';

/// An instance of a Lox [Class].
final class Instance {
  /// Creates a new instance of [class_].
  Instance(Class class_) : _class = class_;

  final Class _class;
  final Map<String, Object?> _fields = {};

  /// Gets the property in the instance with the given [name].
  ///
  /// The property can be either a field or a method.
  ///
  /// If no property with the given [name] exists in the instance, a
  /// [RuntimeError] will be thrown.
  Object? get(Token name) {
    if (_fields.containsKey(name.lexeme)) {
      return _fields[name.lexeme];
    } else if (_class.findMethod(name.lexeme) case final method?) {
      return method.bind(this);
    } else {
      throw RuntimeError(name, "Undefined property '${name.lexeme}'.");
    }
  }

  /// Set the field with given [name] to [value].
  void set(Token name, Object? value) => _fields[name.lexeme] = value;

  @override
  String toString() => '${_class.name} instance';
}
