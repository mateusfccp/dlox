import 'expression.dart';
import 'token.dart';

abstract interface class Statement {
  R accept<R>(StatementVisitor<R> visitor);
}

abstract interface class StatementVisitor<R> {
  R visitBlockStatement(BlockStatement statement);
  R visitExpressionStatement(ExpressionStatement statement);
  R visitIfStatement(IfStatement statement);
  R visitPrintStatement(PrintStatement statement);
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

final class ExpressionStatement implements Statement {
  const ExpressionStatement(this.expression);

  final Expression expression;

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitExpressionStatement(this);
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
