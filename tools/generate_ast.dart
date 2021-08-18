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
      "Expr",
      [
        "Binary   : Expr left, Token operator, Expr right",
        "Grouping : Expr expression",
        "Literal  : Object? value",
        "Unary    : Token operator, Expr right",
      ],
    );
  }
}

void _defineAst(String outputDir, String baseName, List<String> types) {
  final filename = ReCase(baseName).snakeCase;
  final path = '$outputDir/$filename.dart';
  final file = File(path);
  file.createSync(recursive: true);

  // Base class
  final baseClassString = _generateClass(
    className: baseName,
    abstract: true,
    content: '''
    const $baseName._();
    
    R accept<R>(${baseName}Visitor<R> visitor);
    ''',
  );

  final visitorInterfaceString = _defineVisitor(baseName, types);

  // AST classes
  final astClassesString = types.map((type) {
    final className = type.split(':').first.trim();
    final fields = type.split(':').last.trim();
    return _defineType(baseName, className, fields);
  }).join('\n');

  final fileContent = '''
      import 'token.dart';
      
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
    return visitor.visit$className$baseName(this);
  }
  ''';

  final content = '''
  $constructor
  
  $classFields
  
  $acceptMethod
  ''';

  return _generateClass(className: className, content: content, implementsClass: baseName);
}

String _defineVisitor(String baseName, List<String> types) {
  final methodsString = types.map((type) {
    final typeName = type.split(':').first.trim();
    return 'R visit$typeName$baseName($typeName ${baseName.toLowerCase()});';
  }).join('\n');

  return _generateClass(
    className: '${baseName}Visitor',
    abstract: true,
    generics: ['R'],
    content: methodsString,
  );
}

String _generateClass({
  required String className,
  String content = '',
  bool abstract = false,
  String? extendsClass,
  String? implementsClass,
  List<String>? generics,
}) {
  const classTemplate = '''
  {abstract} class {className}{generics} {extends} {implements} {
    {content}
  }
  ''';

  return classTemplate
      .replaceAll('{abstract}', abstract ? 'abstract' : '')
      .replaceAll('{className}', className)
      .replaceAll('{generics}', generics == null || generics.isEmpty ? '' : '<${generics.join(', ')}>')
      .replaceAll('{extends}', extendsClass == null ? '' : 'extends $extendsClass')
      .replaceAll('{implements}', implementsClass == null ? '' : 'implements $implementsClass')
      .replaceAll('{content}', content);
}