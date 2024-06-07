import 'dart:io';

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
    case ParseError() || ScanError():
      exit(dataerr);
    case RuntimeError():
      exit(software);
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

  void handleError() {
    final error = errorHandler.lastError;
    final errorMessage = switch (error) {
      ParseError() when error.token.type == TokenType.endOfFile => '[Line ${error.token.line}] Error at end: ${error.message}',
      ParseError() => "[Line ${error.token.line}] Error at '${error.token.lexeme}': ${error.message}",
      RuntimeError() => '[Line ${error.token.line}] ${error.message}',
      ScanError() => "[Line ${error.line}] ${error.message}",
      null => null,
    };

    if (errorMessage != null) {
      stderr.writeln(errorMessage);
    }
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
