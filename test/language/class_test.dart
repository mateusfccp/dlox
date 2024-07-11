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

  test('A class instance can set values and retrieve them.', () {
    const program = '''
class Foo {}
var foo = Foo();
foo.property = 0;
print foo.property;
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, '0');
  });

  test("A non-instance can't set values.", () {
    const program = '0.property = "value";';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
    );

    var error = errorHandler.errors[0];

    expect(error, isA<NonInstanceTriedToSetFieldError>());
    error as NonInstanceTriedToSetFieldError;

    expect(error.token.type, TokenType.identifier);
    expect(error.token.lexeme, 'property');
    expect(error.token.line, 1);
    expect(error.token.column, 10);
    expect(error.caller, 0);
  });

  test("A class instance can't get values that were not set.", () {
    const program = '''
class Foo {}
var foo = Foo();
print foo.property;
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;
    expect(error, isA<UndefinedPropertyError>());
    error as UndefinedPropertyError;

    expect(error.token.type, TokenType.identifier);
    expect(error.token.lexeme, 'property');
    expect(error.token.line, 3);
    expect(error.token.column, 18);
  });

  test("A non-instance can't get values.", () {
    const program = 'print 0.property;';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
    );

    var error = errorHandler.errors[0];

    expect(error, isA<NonInstanceTriedToGetFieldError>());
    error as NonInstanceTriedToGetFieldError;

    expect(error.token.type, TokenType.identifier);
    expect(error.token.lexeme, 'property');
    expect(error.token.line, 1);
    expect(error.token.column, 16);
    expect(error.caller, 0);
  });

  test('A class can define and call methods.', () {
    const program = '''
class Bacon {
  eat() {
    print "Crunch crunch crunch!";
  }
}

Bacon().eat(); // Prints "Crunch crunch crunch!".
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, 'Crunch crunch crunch!');
  });

  test("Class methods can be assigned through first-class functions.", () {
    const program = '''
class Box {}

fun notMethod(argument) {
  print "called function with " + argument;
}

var box = Box();
box.function = notMethod;
box.function("argument"); // Print "called function with argument"
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, 'called function with argument');
  });

  test("A class correctly binds 'this' to the instance from where it was called.", () {
    const program = '''
class Person {
  sayName() {
    print this.name;
  }
}

var jane = Person();
jane.name = "Jane";

var bill = Person();
bill.name = "Bill";

bill.sayName = jane.sayName;
bill.sayName(); // Print "Jane"
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, 'Jane');
  });

  test("A class can store values in it's environment through the keyword 'this'.", () {
    const program = '''
class Cake {
  taste() {
    var adjective = "delicious";
    print "The " + this.flavor + " cake is " + adjective + "!";
  }
}

var cake = Cake();
cake.flavor = "German chocolate";
cake.taste(); // Prints "The German chocolate cake is delicious!".
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, 'The German chocolate cake is delicious!');
  });

  test("The 'this' keyword can't be used outside of a class.", () {
    const program = '''
fun notAMethod() {
  print this;
}
''';

    resolveSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(
      error,
      isA<ThisUsedOutsideOfClassError>(),
    );
    error as ThisUsedOutsideOfClassError;
    expect(error.token.type, TokenType.thisKeyword);
    expect(error.token.line, 2);
    expect(error.token.column, 12);
  });

  test('Manually calling the initializer of a class should return the class itself.', () {
    const program = '''
    class Foo {
  init() {
    print "Initializing Foo";
  }
}

var foo = Foo();
var init = foo.init();
print foo == init;
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);

    expect(stdout.writtenLines, hasLength(3));
    expect(stdout.writtenLines[0], 'Initializing Foo');
    expect(stdout.writtenLines[1], 'Initializing Foo');
    expect(stdout.writtenLines[2], 'true');
  });

  test("A class initializer can't return any value.", () {
    const program = '''
class Foo {
  init () {
    return 10;
  }
}
''';

    resolveSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<ClassInitializerReturnsValueError>());
    error as ClassInitializerReturnsValueError;
    expect(error.token.line, 3);
    expect(error.token.column, 10);

    final expression = error.value;
    expect(expression, isA<LiteralExpression>());
    expression as LiteralExpression;
    expect(expression.value, 10);
  });

  test('A class initializer can return with no value.', () {
    const program = '''
class Foo {
  init () {
    return;
  }
}
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
    );

    expect(
      errorHandler.errors.isEmpty,
      isTrue,
    );
  });
}
