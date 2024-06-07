/// The type of a Lox routine.
enum RoutineType {
  /// A routine in the global scope of a program.
  function,

  /// A special method that is called when the instance of the class is created.
  initializer,

  /// A routine associated with a class.
  method,
}
