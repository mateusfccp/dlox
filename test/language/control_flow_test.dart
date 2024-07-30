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

  test("'if' conditions should execute if the expression is truthy.", () {
    const program = '''
var a = false;
if (a) print "1";

a = true;
if (a) print "2";
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, '2');
  });

  test("'if' conditions should execute the 'else' block if the expression is untruthy.", () {
    const program = '''
var a = false;

if (a)
  print "1";
else
  print "2";

''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, '2');
  });

  test("Nested 'if' conditions should associate an 'else' keyword with the nearest 'if'.", () {
    const program = '''
var a = true;
var b = false;

if (a)
  if (b)
    print "1";
  else
    print "2";
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, '2');
  });

  test("'unless' conditions should execute if the expression is untruthy.", () {
    const program = '''
var a = false;
unless (a) print "1";

a = true;
unless (a) print "2";
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, '1');
  });

  test("'unless' conditions should execute the 'else' block if the expression is truthy.", () {
    const program = '''
var a = true;

unless (a)
  print "1";
else
  print "2";

''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, '2');
  });

  test("'unless' can be both a keyword and an identifier.", () {
    const program = '''
var unless = 0;
print unless;

unless (unless != 0) {
  print "unless is 0";
}

fun unless(condition, body) {
  unless (condition) {
    body();
  }
}

fun printBody() {
  print("unless function");
}

unless (false) {
  print("unless keyword");
}

unless(false, printBody);
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(
      stdout.writtenLines,
      containsAllInOrder(
        [
          '0',
          'unless is 0',
          'unless keyword',
          'unless function',
        ],
      ),
    );
  });

  test('Logical operators short-cirtuit.', () {
    const program = '''
fun sideEffect(n) {
  print n;
}

false and sideEffect(1); // Short-circuit, shouldn't print
true and sideEffect(2); // Should print
false or sideEffect(3); // Should print
true or sideEffect(4); // Short-circuit, shouldn't print
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines, hasLength(2));
    expect(
      stdout.writtenLines,
      containsAllInOrder(['2', '3']),
    );
  });

  test("'while' loops should run while the given condition is true.", () {
    const program = '''
var i = 0;

while (i < 3) {
  print i;
  i = i + 1;
}
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines, hasLength(3));
    expect(
      stdout.writtenLines,
      containsAllInOrder(['0', '1', '2']),
    );
  });

  test("'for' loops should run while the given condition is true.", () {
    const program = '''
for (var i = 0; i < 3; i = i + 1) {
  print i;
}
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines, hasLength(3));
    expect(
      stdout.writtenLines,
      containsAllInOrder(['0', '1', '2']),
    );
  });
}
