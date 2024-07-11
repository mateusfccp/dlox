import 'package:dlox/dlox.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late ErrorHandler errorHandler;

  setUp(() {
    errorHandler = ErrorHandler();
  });

  test('Unhandled tokens should return a scanning error.', () {
    const program = '''
@

class Foo@ {}
''';

    scanSource(
      source: program,
      errorHandler: errorHandler,
    );

    expect(errorHandler.errors, hasLength(2));

    final error0 = errorHandler.errors[0];

    expect(error0, isA<UnexpectedCharacterError>());
    error0 as UnexpectedCharacterError;

    expect(error0.location.line, 1);
    expect(error0.location.column, 1);
    expect(error0.character, '@');

    final error1 = errorHandler.errors[1];

    expect(error1, isA<UnexpectedCharacterError>());
    error1 as UnexpectedCharacterError;

    expect(error1.location.line, 3);
    expect(error1.location.column, 10);
    expect(error1.character, '@');
  });

  test('Unterminated strings should return a scanning error.', () {
    const program = '''
class MinhaClasse {
    init() {
        echo "String não terminada
    }
}
''';

    scanSource(
      source: program,
      errorHandler: errorHandler,
    );

    expect(errorHandler.errors.length, 1);

    final error = errorHandler.errors.single;

    expect(error, isA<UnterminatedStringError>());
    error as UnterminatedStringError;

    expect(error.location.offset, 76);
    expect(error.location.line, 6);
    expect(error.location.column, 1);
  });
}
