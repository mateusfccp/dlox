import 'token.dart';

abstract interface class Expression {
  R accept<R>(ExpressionVisitor<R> visitor);
}

abstract interface class ExpressionVisitor<R> {
  R visitBinaryExpression(Binary expression);
  R visitGroupingExpression(Grouping expression);
  R visitLiteralExpression(Literal expression);
  R visitUnaryExpression(Unary expression);
}

final class Binary implements Expression {
  const Binary(this.left, this.operator, this.right);

  final Expression left;
  final Token operator;
  final Expression right;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitBinaryExpression(this);
  }
}

final class Grouping implements Expression {
  const Grouping(this.expression);

  final Expression expression;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitGroupingExpression(this);
  }
}

final class Literal implements Expression {
  const Literal(this.value);

  final Object? value;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitLiteralExpression(this);
  }
}

final class Unary implements Expression {
  const Unary(this.operator, this.right);

  final Token operator;
  final Expression right;

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    return visitor.visitUnaryExpression(this);
  }
}
