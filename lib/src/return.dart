/// An exception that emulates a function return.
final class Return implements Exception {
  /// Creates a return.
  const Return(this.value);

  /// The value returned by the function.
  final Object? value;
}
