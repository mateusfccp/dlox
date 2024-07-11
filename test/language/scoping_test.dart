import 'package:dlox/dlox.dart';
import 'package:test/test.dart';

import '../stdout_mock.dart';
import '../utils.dart';

void main() {
  late ErrorHandler errorHandler;
  late StdoutMock stdout;

  setUp(() {
    errorHandler = ErrorHandler();
    stdout = StdoutMock();
  });

  test('Variable scopes are defined by blocks.', () {
    const program = '''
var a = "outer";
{
  print a;
  var a = "inner";
  print a;
}
print a;
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines, hasLength(3));
    expect(stdout.writtenLines[0], 'outer');
    expect(stdout.writtenLines[1], 'inner');
    expect(stdout.writtenLines[2], 'outer');
  });

  test('Variable scopes are captured by closures.', () {
    const program = '''
var a = "global";
{
  fun showA() {
    print a;
  }

  showA();
  var a = "block";
  showA();
}
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines, hasLength(2));
    expect(stdout.writtenLines[0], 'global');
    expect(stdout.writtenLines[1], 'global');
  });

  test("A variable can't initialize its value to itself.", () {
    const program = '''
var a = "outer";
{
  var a = a;
}
''';

    resolveSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<VariableInitializerReadsItselfError>());
    error as VariableInitializerReadsItselfError;

    expect(error.token.type, TokenType.identifier);
    expect(error.token.lexeme, 'a');
    expect(error.token.line, 3);
    expect(error.token.column, 11);
  });

  test("A variable can't be redeclared in the same scope.", () {
    const program = '''
fun bad() {
  var a = "first";
  var a = "second";
}
''';

    resolveSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<VariableAlreadyInScopeError>());
    error as VariableAlreadyInScopeError;

    expect(error.token.type, TokenType.identifier);
    expect(error.token.lexeme, 'a');
    expect(error.token.line, 3);
    expect(error.token.column, 7);
  });

  test("The 'return' keyword can't be used in top-level code.", () {
    const program = 'return "at top level";';

    resolveSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<ReturnUsedOnTopLevelError>());
    error as ReturnUsedOnTopLevelError;

    expect(error.token.type, TokenType.returnKeyword);
    expect(error.token.line, 1);
    expect(error.token.column, 6);
  });
}
