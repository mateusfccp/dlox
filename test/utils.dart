import 'dart:io';

import 'package:dlox/dlox.dart';
import 'package:meta/meta.dart';

@visibleForTesting
List<Token> scanSource({
  required String source,
  ErrorHandler? errorHandler,
}) {
  final scanner = Scanner(
    source: source,
    errorHandler: errorHandler,
  );

  return scanner.scanTokens();
}

@visibleForTesting
List<Statement> parseSource({
  required String source,
  ErrorHandler? errorHandler,
}) {
  final tokens = scanSource(
    source: source,
    errorHandler: errorHandler,
  );

  final parser = Parser(
    tokens: tokens,
    errorHandler: errorHandler,
  );

  return parser.parse();
}

@visibleForTesting
void resolveSource({
  required String source,
  ErrorHandler? errorHandler,
}) {
  final statements = parseSource(
    source: source,
    errorHandler: errorHandler,
  );

  final interpreter = Interpreter(errorHandler: errorHandler);

  final resolver = Resolver(
    interpreter: interpreter,
    errorHandler: errorHandler,
  );

  resolver.resolve(statements);
}

@visibleForTesting
void interpretSource({
  required String source,
  ErrorHandler? errorHandler,
  IOSink? stdout,
}) {
  final statements = parseSource(
    source: source,
    errorHandler: errorHandler,
  );

  final interpreter = Interpreter(
    errorHandler: errorHandler,
    stdout: stdout,
  );

  final resolver = Resolver(
    interpreter: interpreter,
    errorHandler: errorHandler,
  );

  resolver.resolve(statements);
  interpreter.interpret(statements);
}
