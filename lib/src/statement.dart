import 'expression.dart';
import 'token.dart';

abstract interface class Statement {
  R accept<R>(StatementVisitor<R> visitor);
}

abstract interface class StatementVisitor<R> {
  R visitBlockStatement(BlockStatement statement);
  R visitClassStatement(ClassStatement statement);
  R visitExpressionStatement(ExpressionStatement statement);
  R visitFunctionStatement(FunctionStatement statement);
  R visitIfStatement(IfStatement statement);
  R visitPrintStatement(PrintStatement statement);
  R visitReturnStatement(ReturnStatement statement);
  R visitVariableStatement(VariableStatement statement);
  R visitWhileStatement(WhileStatement statement);
}

final class BlockStatement implements Statement {
  const BlockStatement(this.statements);

  final List<Statement> statements;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitBlockStatement(this);
  }
}

final class ClassStatement implements Statement {
  const ClassStatement(this.name, this.superclass, this.methods);

  final Token name;
  final VariableExpression? superclass;
  final List<FunctionStatement> methods;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitClassStatement(this);
  }
}

final class ExpressionStatement implements Statement {
  const ExpressionStatement(this.expression);

  final Expression expression;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitExpressionStatement(this);
  }
}

final class FunctionStatement implements Statement {
  const FunctionStatement(this.name, this.parameters, this.body);

  final Token name;
  final List<Token> parameters;
  final List<Statement> body;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitFunctionStatement(this);
  }
}

final class IfStatement implements Statement {
  const IfStatement(this.condition, this.thenBranch, this.elseBranch);

  final Expression condition;
  final Statement thenBranch;
  final Statement? elseBranch;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitIfStatement(this);
  }
}

final class PrintStatement implements Statement {
  const PrintStatement(this.expression);

  final Expression expression;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitPrintStatement(this);
  }
}

final class ReturnStatement implements Statement {
  const ReturnStatement(this.keyword, this.value);

  final Token keyword;
  final Expression? value;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitReturnStatement(this);
  }
}

final class VariableStatement implements Statement {
  const VariableStatement(this.name, this.initializer);

  final Token name;
  final Expression? initializer;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitVariableStatement(this);
  }
}

final class WhileStatement implements Statement {
  const WhileStatement(this.condition, this.body);

  final Expression condition;
  final Statement body;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitWhileStatement(this);
  }
}
