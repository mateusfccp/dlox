import 'token.dart';

abstract interface class Expression {
  R accept<R>(ExpressionVisitor<R> visitor);
}

abstract interface class ExpressionVisitor<R> {
  R visitAssignExpression(AssignExpression expression);
  R visitBinaryExpression(BinaryExpression expression);
  R visitCallExpression(CallExpression expression);
  R visitGetExpression(GetExpression expression);
  R visitGroupingExpression(GroupingExpression expression);
  R visitLiteralExpression(LiteralExpression expression);
  R visitLogicalExpression(LogicalExpression expression);
  R visitSetExpression(SetExpression expression);
  R visitSuperExpression(SuperExpression expression);
  R visitThisExpression(ThisExpression expression);
  R visitUnaryExpression(UnaryExpression expression);
  R visitVariableExpression(VariableExpression expression);
}

final class AssignExpression implements Expression {
  const AssignExpression(this.name, this.value);

  final Token name;
  final Expression value;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitAssignExpression(this);
  }
}

final class BinaryExpression implements Expression {
  const BinaryExpression(this.left, this.operator, this.right);

  final Expression left;
  final Token operator;
  final Expression right;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitBinaryExpression(this);
  }
}

final class CallExpression implements Expression {
  const CallExpression(this.callee, this.parenthesis, this.arguments);

  final Expression callee;
  final Token parenthesis;
  final List<Expression> arguments;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitCallExpression(this);
  }
}

final class GetExpression implements Expression {
  const GetExpression(this.object, this.name);

  final Expression object;
  final Token name;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitGetExpression(this);
  }
}

final class GroupingExpression implements Expression {
  const GroupingExpression(this.expression);

  final Expression expression;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitGroupingExpression(this);
  }
}

final class LiteralExpression implements Expression {
  const LiteralExpression(this.value);

  final Object? value;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitLiteralExpression(this);
  }
}

final class LogicalExpression implements Expression {
  const LogicalExpression(this.left, this.operator, this.right);

  final Expression left;
  final Token operator;
  final Expression right;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitLogicalExpression(this);
  }
}

final class SetExpression implements Expression {
  const SetExpression(this.object, this.name, this.value);

  final Expression object;
  final Token name;
  final Expression value;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitSetExpression(this);
  }
}

final class SuperExpression implements Expression {
  const SuperExpression(this.keyword, this.method);

  final Token keyword;
  final Token method;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitSuperExpression(this);
  }
}

final class ThisExpression implements Expression {
  const ThisExpression(this.keyword);

  final Token keyword;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitThisExpression(this);
  }
}

final class UnaryExpression implements Expression {
  const UnaryExpression(this.operator, this.right);

  final Token operator;
  final Expression right;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitUnaryExpression(this);
  }
}

final class VariableExpression implements Expression {
  const VariableExpression(this.name);

  final Token name;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitVariableExpression(this);
  }
}
