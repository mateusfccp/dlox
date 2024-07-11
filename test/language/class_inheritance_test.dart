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

  test("A class can't inherit from itself.", () {
    const program = 'class Self < Self {}';

    resolveSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<ClassInheritsFromItselfError>());
    error as ClassInheritsFromItselfError;

    expect(error.token.type, TokenType.identifier);
    expect(error.token.lexeme, 'Self');
    expect(error.token.line, 1);
    expect(error.token.column, 17);
  });

  test("A class can't inherit from a non-class.", () {
    const program = '''
var NonClass = "Not a class!";
class Self < NonClass {} // Error: NonClass is not a class
        ''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.first;

    expect(error, isA<ClassInheritsFromANonClassError>());
    error as ClassInheritsFromANonClassError;

    expect(error.token.type, TokenType.identifier);
    expect(error.token.lexeme, 'NonClass');
    expect(error.token.line, 2);
    expect(error.token.column, 21);
  });

  test("The 'super' keyword can't be used outside of a class.", () {
    const program = 'super.anything();';

    resolveSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<SuperUsedOutsideOfClassError>());
    error as SuperUsedOutsideOfClassError;

    expect(error.token.type, TokenType.superKeyword);
    expect(error.token.line, 1);
    expect(error.token.column, 5);
  });

  test("The 'super' keyword must always be followed by an identifier.", () {
    const program = '''
class Doughnut {}

class BostonCream < Doughnut {
    cook() {
        print super; // Syntax error
    }
}
''';

    parseSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<ExpectAfterError>());
    error as ExpectAfterError;

    expect(error.token.type, TokenType.semicolon);
    expect(error.token.line, 5);
    expect(error.token.column, 20);
    expect(error.expectation, TokenExpectation(token: TokenType.dot));
    expect(error.after, TokenExpectation(token: TokenType.superKeyword));
  });

  test("The 'super' keyword can't be used in a class with no superclass.", () {
    const program = '''
class Root {
    init () {
        super.doSomething(); // Can't use 'super' in a class with no superclass
    }
}
''';

    resolveSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<SuperUsedInAClassWithoutSuperclassError>());
    error as SuperUsedInAClassWithoutSuperclassError;

    expect(error.token.type, TokenType.superKeyword);
    expect(error.token.line, 3);
    expect(error.token.column, 13);
  });

  test("A class can't call a non-existent super-method.", () {
    const program = '''
class Doughnut {}

class BostonCream < Doughnut {
    cook() {
        super.cook();
        print "Pipe full of custard and coat with chocolate.";
    }
}

BostonCream().cook(); // "Pipe full of custard and coat with chocolate.
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    final error = errorHandler.errors.single;

    expect(
      error,
      isA<UndefinedPropertyError>(),
    );
    error as UndefinedPropertyError;

    expect(error.token.type, TokenType.identifier);
    expect(error.token.lexeme, 'cook');
    expect(error.token.line, 5);
    expect(error.token.column, 18);
  });

  test('A class should call parent method when method is not implemented.', () {
    const program = '''
class Doughnut {
    cook() {
        print "Fry until golden brown.";
    }
}

class BostonCream < Doughnut {}

BostonCream().cook(); // "Fry until golden brown."
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);

    expect(
      stdout.writtenLines.single,
      "Fry until golden brown.",
    );
  });

  test("A class should call it's own method when method is implemented.", () {
    const program = '''
class Doughnut {
    cook() {
      print "Fry until golden brown.";
    }
}

class BostonCream < Doughnut {
    cook() {
      print "Pipe full of custard and coat with chocolate.";
    }
}

BostonCream().cook(); // "Pipe full of custard and coat with chocolate.
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);

    expect(
      stdout.writtenLines.single,
      "Pipe full of custard and coat with chocolate.",
    );
  });

  test("A class should call the parent's method when 'super' is called and the parent has the called method.", () {
    const program = '''
class Doughnut {
    cook() {
      print "Fry until golden brown.";
    }
}

class BostonCream < Doughnut {
    cook() {
        super.cook();
        print "Pipe full of custard and coat with chocolate.";
    }
}

BostonCream().cook(); // "Pipe full of custard and coat with chocolate.
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);

    expect(stdout.writtenLines, hasLength(2));

    expect(
      stdout.writtenLines[0],
      "Fry until golden brown.",
    );

    expect(
      stdout.writtenLines[1],
      "Pipe full of custard and coat with chocolate.",
    );
  });
}
