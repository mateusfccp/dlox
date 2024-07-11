import 'error.dart';
import 'expression.dart';
import 'routine_type.dart';
import 'statement.dart';
import 'token.dart';

/// A Lox parser.
final class Parser {
  /// Creates a Lox parser.
  Parser({
    required List<Token> tokens,
    ErrorHandler? errorHandler,
  })  : _errorHandler = errorHandler,
        _tokens = tokens;

  final List<Token> _tokens;
  final ErrorHandler? _errorHandler;

  int _current = 0;

  Token get _previous => _tokens[_current - 1];

  Token get _peek => _tokens[_current];

  bool get _isAtEnd => _peek.type == TokenType.endOfFile;

  bool get _isNotAtEnd => !_isAtEnd;

  List<Statement> parse() {
    return [
      for (; !_isAtEnd;)
        if (_declaration() case final declaration?) declaration,
    ];
  }

  bool _match(TokenType type1, [TokenType? type2, TokenType? type3, TokenType? type4]) {
    final types = [type1, type2, type3, type4].nonNulls;

    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }

    return false;
  }

  bool _check(TokenType type) => _isNotAtEnd && _peek.type == type;

  Token _advance() {
    if (_isNotAtEnd) _current++;
    return _previous;
  }

  Token _consume(TokenType type, ParseError error) {
    if (_check(type)) {
      return _advance();
    } else {
      _errorHandler?.emit(error);
      throw error;
    }
  }

  void _synchronize() {
    _advance();
    while (_isNotAtEnd) {
      if (_previous.type == TokenType.semicolon) {
        return;
      } else {
        switch (_peek.type) {
          case TokenType.classKeyword:
          case TokenType.forKeyword:
          case TokenType.funKeyword:
          case TokenType.ifKeyword:
          case TokenType.printKeyword:
          case TokenType.returnKeyword:
          case TokenType.varKeyword:
          case TokenType.whileKeyword:
            return;
          default:
            _advance();
        }
      }
    }
  }

  Expression _expression() => _assignment();

  Statement? _declaration() {
    try {
      if (_match(TokenType.classKeyword)) {
        return _class();
      } else if (_match(TokenType.funKeyword)) {
        return _function(RoutineType.function);
      } else if (_match(TokenType.varKeyword)) {
        return _variableDeclaration();
      } else {
        return _statement();
      }
    } on ParseError {
      _synchronize();
      return null;
    }
  }

  Statement _statement() {
    if (_match(TokenType.forKeyword)) {
      return _forStatement();
    } else if (_match(TokenType.ifKeyword)) {
      return _ifStatement();
    } else if (_match(TokenType.printKeyword)) {
      return _printStatement();
    } else if (_match(TokenType.returnKeyword)) {
      return _returnStatement();
    } else if (_match(TokenType.whileKeyword)) {
      return _whileStatement();
    } else if (_match(TokenType.leftBrace)) {
      return BlockStatement(_block());
    } else {
      return _expressionStatement();
    }
  }

  Statement _class() {
    final name = _consume(
      TokenType.identifier,
      ExpectError(
        token: _peek,
        expectation: TokenExpectation(
          token: TokenType.identifier,
          description: 'class name',
        ),
      ),
    );
    final VariableExpression? superclass;

    if (_match(TokenType.less)) {
      _consume(
        TokenType.identifier,
        ExpectError(
          token: _peek,
          expectation: TokenExpectation(
            token: TokenType.identifier,
            description: 'superclass name',
          ),
        ),
      );
      superclass = VariableExpression(_previous);
    } else {
      superclass = null;
    }

    _consume(
      TokenType.leftBrace,
      ExpectAfterError(
        token: _peek,
        expectation: TokenExpectation(token: TokenType.leftBrace),
        after: TokenExpectation(
          token: TokenType.identifier,
          description: 'class name',
        ),
      ),
    );

    final methods = <FunctionStatement>[];

    while (!_check(TokenType.rightBrace) && !_isAtEnd) {
      methods.add(_function(RoutineType.method));
    }

    _consume(
      TokenType.rightBrace,
      ExpectAfterError(
        token: _peek,
        expectation: TokenExpectation(token: TokenType.rightBrace),
        after: methods.isEmpty //
            ? TokenExpectation(
                token: TokenType.leftBrace,
                description: 'class body',
              )
            : StatementExpectation(
                statement: methods.last,
                description: 'class body',
              ),
      ),
    );

    return ClassStatement(
      name,
      superclass,
      methods,
    );
  }

  Statement _forStatement() {
    _consume(
      TokenType.leftParenthesis,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.leftParenthesis),
        after: TokenExpectation(token: TokenType.forKeyword),
      ),
    );

    final Statement? initializer;
    if (_match(TokenType.semicolon)) {
      initializer = null;
    } else if (_match(TokenType.varKeyword)) {
      initializer = _variableDeclaration();
    } else {
      initializer = _expressionStatement();
    }

    final Expression? condition;
    if (_check(TokenType.semicolon)) {
      condition = null;
    } else {
      condition = _expression();
    }

    _consume(
      TokenType.semicolon,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.semicolon),
        after: condition == null //
            ? TokenExpectation(token: TokenType.semicolon, description: 'loop condition')
            : ExpressionExpectation(expression: condition, description: 'loop condition'),
      ),
    );

    final Expression? increment;
    if (_check(TokenType.rightParenthesis)) {
      increment = null;
    } else {
      increment = _expression();
    }

    _consume(
      TokenType.rightParenthesis,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.rightParenthesis),
        after: increment == null //
            ? TokenExpectation(token: TokenType.semicolon, description: 'for clauses')
            : ExpressionExpectation(expression: increment, description: 'for clauses'),
      ),
    );

    final body = _statement();

    return BlockStatement([
      if (initializer != null) initializer,
      WhileStatement(
        condition ?? LiteralExpression(true),
        BlockStatement([
          body,
          if (increment != null) ExpressionStatement(increment),
        ]),
      ),
    ]);
  }

  Statement _ifStatement() {
    _consume(
      TokenType.leftParenthesis,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.leftParenthesis),
        after: TokenExpectation(token: TokenType.ifKeyword),
      ),
    );

    final condition = _expression();

    _consume(
      TokenType.rightParenthesis,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.rightParenthesis),
        after: ExpressionExpectation(expression: condition, description: 'if condition'),
      ),
    );

    final thenBranch = _statement();

    final Statement? elseBranch;

    if (_match(TokenType.elseKeyword)) {
      elseBranch = _statement();
    } else {
      elseBranch = null;
    }

    return IfStatement(condition, thenBranch, elseBranch);
  }

  Statement _printStatement() {
    final value = _expression();
    _consume(
      TokenType.semicolon,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.semicolon),
        after: ExpressionExpectation(expression: value, description: 'value'),
      ),
    );
    return PrintStatement(value);
  }

  Statement _returnStatement() {
    final keyword = _previous;

    final Expression? value;
    if (_check(TokenType.semicolon)) {
      value = null;
    } else {
      value = _expression();
    }

    _consume(
      TokenType.semicolon,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.semicolon),
        after: value == null //
            ? TokenExpectation(token: TokenType.returnKeyword, description: 'return value')
            : ExpressionExpectation(expression: value, description: 'return value'),
      ),
    );

    return ReturnStatement(keyword, value);
  }

  Statement _variableDeclaration() {
    final name = _consume(
      TokenType.identifier,
      ExpectError(
        token: _peek,
        expectation: ExpectationType.token(
          token: TokenType.identifier,
          description: 'variable name',
        ),
      ),
    );

    final Expression? initializer;

    if (_match(TokenType.equal)) {
      initializer = _expression();
    } else {
      initializer = null;
    }

    _consume(
      TokenType.semicolon,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.semicolon),
        after: initializer == null //
            ? TokenExpectation(token: TokenType.identifier, description: 'variable declaration')
            : ExpressionExpectation(expression: initializer, description: 'variable declaration'),
      ),
    );

    return VariableStatement(name, initializer);
  }

  Statement _whileStatement() {
    _consume(
      TokenType.leftParenthesis,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.leftParenthesis),
        after: TokenExpectation(token: TokenType.whileKeyword),
      ),
    );

    final condition = _expression();

    _consume(
      TokenType.rightParenthesis,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.rightParenthesis),
        after: ExpressionExpectation(expression: condition, description: 'while condition'),
      ),
    );

    return WhileStatement(condition, _statement());
  }

  Statement _expressionStatement() {
    final expression = _expression();
    _consume(
      TokenType.semicolon,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.semicolon),
        after: ExpressionExpectation(expression: expression),
      ),
    );

    return ExpressionStatement(expression);
  }

  FunctionStatement _function(RoutineType functionType) {
    final name = _consume(
      TokenType.identifier,
      ExpectError(
        token: _peek,
        expectation: ExpectationType.token(
          token: TokenType.identifier,
          description: '$functionType name',
        ),
      ),
    );
    final parameters = <Token>[];
    _consume(
      TokenType.leftParenthesis,
      ExpectError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.leftParenthesis),
      ),
    );

    if (!_check(TokenType.rightParenthesis)) {
      do {
        if (parameters.length >= 255) {
          _errorHandler?.emit(
            ParametersLimitError(token: _peek),
          );
        }

        parameters.add(
          _consume(
            TokenType.identifier,
            ExpectError(
              token: _peek,
              expectation: ExpectationType.token(
                token: TokenType.identifier,
                description: 'parameter name',
              ),
            ),
          ),
        );
      } while (_match(TokenType.comma));
    }

    _consume(
      TokenType.rightParenthesis,
      ExpectError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.rightParenthesis),
      ),
    );
    _consume(
      TokenType.leftBrace,
      ExpectBeforeError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.leftBrace),
        before: StatementExpectation(
          statement: BlockStatement([]), // TODO(mateusfccp): Review this
          description: '$functionType body',
        ),
      ),
    );

    return FunctionStatement(name, parameters, _block());
  }

  List<Statement> _block() {
    final statements = <Statement>[];

    while (!_check(TokenType.rightBrace) && !_isAtEnd) {
      final declaration = _declaration();

      if (declaration != null) {
        statements.add(declaration);
      }
    }

    _consume(
      TokenType.rightBrace,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.rightBrace),
        after: StatementExpectation(
          // TODO(mateufccp): Review this
          statement: BlockStatement(statements),
          description: 'block',
        ),
      ),
    );
    return statements;
  }

  Expression _assignment() {
    final expression = _or();

    if (_match(TokenType.equal)) {
      final equals = _previous;
      final value = _assignment();

      if (expression is VariableExpression) {
        return AssignExpression(expression.name, value);
      } else if (expression is GetExpression) {
        return SetExpression(expression.object, expression.name, value);
      } else {
        _errorHandler?.emit(
          InvalidAssignmentTargetError(token: equals),
        );
      }
    }

    return expression;
  }

  Expression _or() {
    var expression = _and();

    while (_match(TokenType.orKeyword)) {
      expression = LogicalExpression(
        expression,
        _previous,
        _equality(),
      );
    }

    return expression;
  }

  Expression _and() {
    var expression = _equality();

    while (_match(TokenType.andKeyword)) {
      expression = LogicalExpression(
        expression,
        _previous,
        _equality(),
      );
    }

    return expression;
  }

  Expression _equality() {
    var expression = _comparison();

    while (_match(TokenType.bangEqual, TokenType.equalEqual)) {
      final operator = _previous;
      final right = _comparison();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _comparison() {
    var expression = _term();

    while (_match(TokenType.greater, TokenType.greaterEqual, TokenType.less, TokenType.lessEqual)) {
      final operator = _previous;
      final right = _term();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _term() {
    var expression = _factor();

    while (_match(TokenType.minus, TokenType.plus)) {
      final operator = _previous;
      final right = _factor();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _factor() {
    var expression = _unary();

    while (_match(TokenType.slash, TokenType.asterisk)) {
      final operator = _previous;
      final right = _unary();
      expression = BinaryExpression(expression, operator, right);
    }

    return expression;
  }

  Expression _unary() {
    if (_match(TokenType.bang, TokenType.minus)) {
      final operator = _previous;
      final right = _unary();
      return UnaryExpression(operator, right);
    } else {
      return _call();
    }
  }

  Expression _finishCall(Expression callee) {
    final arguments = <Expression>[];

    if (!_check(TokenType.rightParenthesis)) {
      do {
        if (arguments.length >= 255) {
          _errorHandler?.emit(
            ArgumentsLimitError(token: _peek),
          );
        }
        arguments.add(_expression());
      } while (_match(TokenType.comma));
    }

    final parenthesis = _consume(
      TokenType.rightParenthesis,
      ExpectAfterError(
        token: _peek,
        expectation: ExpectationType.token(token: TokenType.rightParenthesis),
        after: TokenExpectation(
          token: arguments.isEmpty //
              ? TokenType.leftParenthesis
              : TokenType.identifier,
          description: 'arguments',
        ),
      ),
    );

    return CallExpression(callee, parenthesis, arguments);
  }

  Expression _call() {
    var expression = _primary();

    while (true) {
      if (_match(TokenType.leftParenthesis)) {
        expression = _finishCall(expression);
      } else if (_match(TokenType.dot)) {
        final name = _consume(
          TokenType.identifier,
          ExpectAfterError(
            token: _peek,
            expectation: ExpectationType.token(
              token: TokenType.identifier,
              description: 'property name',
            ),
            after: TokenExpectation(token: TokenType.comma),
          ),
        );
        expression = GetExpression(expression, name);
      } else {
        break;
      }
    }

    return expression;
  }

  Expression _primary() {
    if (_match(TokenType.falseKeyword)) {
      return LiteralExpression(false);
    } else if (_match(TokenType.trueKeyword)) {
      return LiteralExpression(true);
    } else if (_match(TokenType.nilKeyword)) {
      return LiteralExpression(null);
    } else if (_match(TokenType.number, TokenType.string)) {
      return LiteralExpression(_previous.literal);
    } else if (_match(TokenType.superKeyword)) {
      final keyword = _previous;
      _consume(
        TokenType.dot,
        ExpectAfterError(
          token: _peek,
          expectation: ExpectationType.token(token: TokenType.dot),
          after: TokenExpectation(token: TokenType.superKeyword),
        ),
      );

      final method = _consume(
        TokenType.identifier,
        ExpectError(
          token: _peek,
            expectation: ExpectationType.token(
              token: TokenType.identifier,
              description: 'superclass method name',
            )
        ),
      );

      return SuperExpression(keyword, method);
    } else if (_match(TokenType.thisKeyword)) {
      return ThisExpression(_previous);
    } else if (_match(TokenType.identifier)) {
      return VariableExpression(_previous);
    } else if (_match(TokenType.leftParenthesis)) {
      final expression = _expression();
      _consume(
        TokenType.rightParenthesis,
        ExpectAfterError(
          token: _peek,
          expectation: ExpectationType.token(token: TokenType.rightParenthesis),
          after: ExpressionExpectation(expression: expression),
        ),
      );

      return GroupingExpression(expression);
    } else {
      final error = ExpectError(
        token: _peek,
        expectation: ExpectationType.expression(),
      );

      _errorHandler?.emit(error);
      throw error;
    }
  }
}
