import 'dart:io';

import 'package:dlox/dlox.dart';
import 'package:quiver/strings.dart';

import 'src/sysexit.dart';

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

  if (error is ParseError) {
    exit(dataerr);
  } else if (error is RuntimeError) {
    exit(software);
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

DloxError? run(String source) {
  final scanner = Scanner(source);
  final tokens = scanner.scanTokens();

  final parser = Parser(tokens);

  try {
    final expression = parser.parse();
    final interpreter = Interpreter();
    final result = interpreter.interpretAndReturnStringRepresentation(expression);

    stdout.writeln(result);
  } on DloxError catch (e) {
    stderr.writeln(error(e));
    return e;
  }
}

String error(DloxError error) {
  if (error is ParseError) {
    if (error.token.type == TokenType.endOfFile) {
      return '[Line ${error.token.line}] Error at end: ${error.message}';
    } else {
      return "[Line ${error.token.line}] Error at '${error.token.lexeme}': ${error.message}";
    }
  } else if (error is RuntimeError) {
    return '[Line ${error.token.line}] ${error.message}';
  } else {
    // TODO(mateusfccp): Properly deal with non-possible case
    throw error;
  }
}

