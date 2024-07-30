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

  test('The unary minus operator must have a numeric operand.', () {
    const validProgram = '-10;';

    interpretSource(
      source: validProgram,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);

    const invalidProgram = '-"muffin";';

    interpretSource(
      source: invalidProgram,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;
    expect(error, isA<InvalidOperandForUnaryMinusOperatorError>());
    error as InvalidOperandForUnaryMinusOperatorError;
    expect(error.token.type, TokenType.minus);
    expect(error.token.line, 1);
    expect(error.token.column, 1);
    expect(error.right, 'muffin');
  });

  test('The plus operator operators must be numeric or strings.', () {
    const validProgram = '''
print(10 + 10); // 20
print("foo" + "bar"); //foobar
''';

    interpretSource(
      source: validProgram,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines[0], '20');
    expect(stdout.writtenLines[1], 'foobar');

    const invalidProgram = 'true + false;';

    interpretSource(
      source: invalidProgram,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;
    expect(error, isA<InvalidOperandsForPlusOperatorError>());
    error as InvalidOperandsForPlusOperatorError;
    expect(error.token.type, TokenType.plus);
    expect(error.token.line, 1);
    expect(error.token.column, 6);
    expect(error.left, true);
    expect(error.right, false);
  });

  test("The plus operator can't have operands of different types, even if they are numeric and strings.", () {
    const program = '"a" + 10;';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    final error = errorHandler.errors.single;
    expect(error, isA<InvalidOperandsForPlusOperatorError>());
    error as InvalidOperandsForPlusOperatorError;
    expect(error.token.type, TokenType.plus);
    expect(error.token.line, 1);
    expect(error.token.column, 5);
    expect(error.left, 'a');
    expect(error.right, 10);
  });

  void testBinaryNumericOperator({
    required String operatorName,
    required String expectation,
    required TokenType operatorType,
  }) {
    test("The $operatorName operator can only have numeric operators.", () {
      final program = '''
print(10 $operatorType 10); // Ok
print("foo" $operatorType "bar"); // Error
''';

      interpretSource(
        source: program,
        errorHandler: errorHandler,
        stdout: stdout,
      );

      expect(stdout.writtenLines.single, expectation);

      final error = errorHandler.errors.single;
      expect(error, isA<InvalidOperandsForNumericBinaryOperatorsError>());
      error as InvalidOperandsForNumericBinaryOperatorsError;
      expect(error.token.type, operatorType);
      expect(error.token.line, 2);
      expect(error.token.column, 12 + '$operatorType'.length);
      expect(error.left, 'foo');
      expect(error.right, 'bar');
    });
  }

  testBinaryNumericOperator(
    operatorName: 'minus',
    expectation: '0',
    operatorType: TokenType.minus,
  );

  testBinaryNumericOperator(
    operatorName: 'asterisk',
    expectation: '100',
    operatorType: TokenType.asterisk,
  );

  testBinaryNumericOperator(
    operatorName: 'slash',
    expectation: '1',
    operatorType: TokenType.slash,
  );

  testBinaryNumericOperator(
    operatorName: 'greater than',
    expectation: 'false',
    operatorType: TokenType.greater,
  );

  testBinaryNumericOperator(
    operatorName: 'greater than or equal to',
    expectation: 'true',
    operatorType: TokenType.greaterEqual,
  );

  testBinaryNumericOperator(
    operatorName: 'less than',
    expectation: 'false',
    operatorType: TokenType.less,
  );

  testBinaryNumericOperator(
    operatorName: 'less than or equal to',
    expectation: 'true',
    operatorType: TokenType.lessEqual,
  );
}
