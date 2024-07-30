import 'dart:convert';
import 'dart:io';

import 'package:chalkdart/chalkstrings.dart';
import 'package:dlox/dlox.dart';
import 'package:exitcode/exitcode.dart';
import 'package:quiver/strings.dart';

void main(List<String> args) {
  if (args.length > 1) {
    stderr.writeln('Usage: dlox [script]');
    exit(usage);
  } else if (args.length == 1) {
    runFile(args.single);
  } else {
    runPrompt();
  }
}

void runFile(String path) {
  final fileString = File(path).readAsStringSync();
  final error = run(fileString);

  switch (error) {
    case RuntimeError():
      exit(software);
    case LoxError():
      exit(dataerr);
    case null:
      break;
  }
}

void runPrompt() {
  for (;;) {
    stdout.write('› ');
    final line = stdin.readLineSync();
    if (line == null || isBlank(line)) break;
    run(line);
  }
}

LoxError? run(String source) {
  final errorHandler = ErrorHandler();

  final lineSplitter = LineSplitter(); // TODO(mateusfccp): Convert the handler into an interface and put this logic inside
  final lines = lineSplitter.convert(source);
  if (source.endsWith('\n')) {
    lines.add('');
  }

  String getLineWithErrorPointer(int line, int column) {
    final buffer = StringBuffer();

    void addLine(int line) {
      buffer.writeln('${chalk.gray('$line: ')}${lines[line - 1]}');
    }

    if (line - 1 >= 1) {
      addLine(line - 1);
    }

    addLine(line);

    buffer.write('   '); // Padding equivalent to the line indicators

    for (int i = 0; i < column - 1; i++) {
      buffer.write(' ');
    }

    buffer.writeln('⬆');

    if (lines.length > line) {
      addLine(line + 1);
    }

    return buffer.toString();
  }

  void handleError() {
    final error = errorHandler.lastError;
    if (error == null) return;

    final errorHeader = switch (error) {
      ParseError() when error.token.type == TokenType.endOfFile => '[${error.token.line}:${error.token.column}] Error at end:',
      ParseError() => "[${error.token.line}:${error.token.column}]:",
      ResolveError() => "[${error.token.line}:${error.token.column}] Error at '${error.token.lexeme}':",
      RuntimeError() => '[${error.token.line}:${error.token.column}]:',
      ScanError() => '[${error.location.line}:${error.location.column}]:'
    };

    final errorMessage = switch (error) {
      // Parse errors
      ExpectError(:final expectation) => 'Expected to find $expectation.',
      ExpectAfterError(:final expectation, :final after) => 'Expected to find $expectation after $after.',
      ExpectBeforeError(:final expectation, :final before) => 'Expected to find $expectation before $before.',
      ParametersLimitError() => "A function/method can't have more than 255 parameters.",
      ArgumentsLimitError() => "A function/method call can't have more than 255 arguments.",
      InvalidAssignmentTargetError() => 'Invalid assignment target.',
      // Resolve errors
      ClassInheritsFromItselfError() => "A class can't inherit from itself.",
      ClassInitializerReturnsValueError(:final value) => "A class initializer can't return a value. Tried to return the expression '$value'.",
      SuperUsedInAClassWithoutSuperclassError() => "The keyword 'super' can't be used in a class with no superclass.",
      SuperUsedOutsideOfClassError() => "The keyword 'super' can't be used outside of a class.",
      ThisUsedOutsideOfClassError() => "The keyword 'this' can't be used outside of a class.",
      VariableAlreadyInScopeError(:final token) => "There's already a variable named `${token.lexeme}` in this scope.",
      VariableInitializerReadsItselfError() => "A local variable can't read itself in its own initializer.",
      ReturnUsedOnTopLevelError() => "The 'return' keyword can't be used in top-level code. It should be within a function or method.",
      // Runtime errors
      ArityError(:final arity, :final argumentsCount) => 'Expected $arity arguments but got $argumentsCount.',
      ClassInheritsFromANonClassError(:final token) => 'Superclass must be a class, but ${token.lexeme} is not a class.',
      InvalidOperandsForNumericBinaryOperatorsError(:final token, :final left, :final right) => "The operands for the operator '${token.lexeme}' should be numeric. '$left' and/or '$right' is/are not numeric.",
      InvalidOperandForUnaryMinusOperatorError(:final right) => "The operand for the unary minus operator should be a number. Got '$right'.",
      InvalidOperandsForPlusOperatorError(:final token, :final left, :final right) => "The operands for the operator '${token.lexeme}' should be both numeric or both strings. '$left' and/or '$right' do(es) not fulfill this requirement.",
      NonRoutineCalledError(:final callee) => "The expression '${callee}' can't be called. Only functions, methods and classes can be called.",
      NonInstanceTriedToGetFieldError(:final token, :final caller) || //
      NonInstanceTriedToSetFieldError(:final token, :final caller) =>
        "Only instances have fields. '${token.lexeme}', of type ${caller.runtimeType}, is not an instance of a class.",
      UndefinedPropertyError(:final token) => "Undefined property '${token.lexeme}'.",
      UndefinedVariableError(:final token) => "Undefined variable '${token.lexeme}'.",
      // Scan errors
      UnexpectedCharacterError() => "Unexpected character '${error.character}'.",
      UnterminatedStringError() => 'Unexpected string termination.',
    };

    final lineHint = switch (error) {
      ScanError() => getLineWithErrorPointer(error.location.line, error.location.column),
      ParseError(:final token) || ResolveError(:final token) || RuntimeError(:final token) => getLineWithErrorPointer(token.line, token.column),
    };

    stderr.writeln(chalk.yellowBright(errorHeader + errorMessage));
    stderr.writeln(lineHint);
  }

  errorHandler.addListener(handleError);

  final scanner = Scanner(
    source: source,
    errorHandler: errorHandler,
  );

  final tokens = scanner.scanTokens();

  final parser = Parser(
    tokens: tokens,
    errorHandler: errorHandler,
  );

  final statements = parser.parse();

  if (errorHandler.hasError) {
    return errorHandler.lastError;
  }

  final interpreter = Interpreter(errorHandler: errorHandler);

  final resolver = Resolver(
    interpreter: interpreter,
    errorHandler: errorHandler,
  );

  resolver.resolve(statements);

  if (errorHandler.hasError) {
    return errorHandler.lastError;
  }

  interpreter.interpret(statements);

  return errorHandler.lastError;
}
