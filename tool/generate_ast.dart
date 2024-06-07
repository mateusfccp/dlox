import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: generate_ast <output directory>');
    exit(64); // exit(usage)
  } else {
    final outputDir = args.first;
    _defineAst(
      outputDir,
      'Expression',
      [
        'Assign   : Token name, Expression value',
        'Binary   : Expression left, Token operator, Expression right',
        'Call     : Expression callee, Token parenthesis, List<Expression> arguments',
        'Get      : Expression object, Token name',
        'Grouping : Expression expression',
        'Literal  : Object? value',
        'Logical  : Expression left, Token operator, Expression right',
        'Set      : Expression object, Token name, Expression value',
        'Super    : Token keyword, Token method',
        'This     : Token keyword',
        'Unary    : Token operator, Expression right',
        'Variable : Token name',
      ],
      ['token.dart'],
    );

    _defineAst(
      outputDir,
      'Statement',
      [
        'Block      : List<Statement> statements',
        'Class      : Token name, VariableExpression? superclass, List<FunctionStatement> methods',
        'Expression : Expression expression',
        'Function   : Token name, List<Token> parameters, List<Statement> body',
        'If         : Expression condition, Statement thenBranch, Statement? elseBranch',
        'Print      : Expression expression',
        'Return     : Token keyword, Expression? value',
        'Variable   : Token name, Expression? initializer',
        'While      : Expression condition, Statement body',
      ],
      ['expression.dart', 'token.dart'],
    );
  }
}

void _defineAst(
  String outputDir,
  String baseName,
  List<String> types, [
  List<String> imports = const [],
]) {
  final filename = ReCase(baseName).snakeCase;
  final path = '$outputDir/$filename.dart';
  final file = File(path);
  file.createSync(recursive: true);

  // Imports
  final importsString = imports.map((import) => "import '$import';").join('\n');

  // Base class
  final baseClassString = _generateClass(
    className: baseName,
    abstract: true,
    interface: true,
    content: '''
    R accept<R>(${baseName}Visitor<R> visitor);
    ''',
  );

  final visitorInterfaceString = _defineVisitor(baseName, types);

  // AST classes
  final astClassesString = types.map((type) {
    final baseClassName = type.split(':').first.trim();
    final className = '$baseClassName$baseName';
    final fields = type.split(':').last.trim();
    return _defineType(baseName, className, fields);
  }).join('\n');

  final fileContent = '''
      $importsString
      
      $baseClassString
      $visitorInterfaceString
      $astClassesString
  ''';

  final formatter = DartFormatter();
  final formattedString = formatter.format(fileContent);

  file.writeAsStringSync(formattedString);
}

String _defineType(String baseName, String className, String fieldList) {
  final fields = fieldList.split(', ');

  final constructorFields = fields.map((field) => 'this.${field.split(' ').last}').join(', ');
  final constructor = 'const $className($constructorFields);';

  final classFields = fields.map((field) => 'final $field;').join('\n');

  final acceptMethod = '''
  @override
  R accept<R>(${baseName}Visitor<R> visitor) {
    return visitor.visit$className(this);
  }
  ''';

  final content = '''
  $constructor
  
  $classFields
  
  $acceptMethod
  ''';

  return _generateClass(
    final_: true,
    className: className,
    content: content,
    implementsClass: baseName,
  );
}

String _defineVisitor(String baseName, List<String> types) {
  final methodsString = types.map((type) {
    final baseTypeName = type.split(':').first.trim();
    final typeName = '$baseTypeName$baseName';
    return 'R visit$baseTypeName$baseName($typeName ${baseName.toLowerCase()});';
  }).join('\n');

  return _generateClass(
    className: '${baseName}Visitor',
    abstract: true,
    interface: true,
    generics: ['R'],
    content: methodsString,
  );
}

String _generateClass({
  required String className,
  String content = '',
  bool final_ = false,
  bool abstract = false,
  bool interface = false,
  String? extendsClass,
  String? implementsClass,
  List<String>? generics,
}) {
  assert(final_ != abstract && final_ != interface);

  const classTemplate = '''
  {final} {abstract} {interface} class {className}{generics} {extends} {implements} {
    {content}
  }
  ''';

  return classTemplate
      .replaceAll('{final}', final_ ? 'final' : '')
      .replaceAll('{abstract}', abstract ? 'abstract' : '')
      .replaceAll('{interface}', interface ? 'interface' : '')
      .replaceAll('{className}', className)
      .replaceAll('{generics}', generics == null || generics.isEmpty ? '' : '<${generics.join(', ')}>')
      .replaceAll('{extends}', extendsClass == null ? '' : 'extends $extendsClass')
      .replaceAll('{implements}', implementsClass == null ? '' : 'implements $implementsClass')
      .replaceAll('{content}', content);
}
