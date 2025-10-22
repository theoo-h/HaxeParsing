package lite;

import haxe.Template;
import lite.Expr;
import lite.Token;
import lite.Token;
import lite.core.LiteException;

/**
 * STILL PRETTY PRETTY WIP
 * ITS MY FIRST TIME MAKING AN ACTUAL AST SO IT MAY CRASH RANDOMLY
 */
class Parser {
	var tokens:Array<Token> = [];

	public function new(tokens:Array<Token>) {
		this.tokens = tokens;
	}

	var position:UInt;

	public function run() {
		var nodes:Array<Expr> = [];

		position = 0;

		while (position < tokens.length) {
			final node = resolveNode();

			if (node != null) {
				nodes.push(node);

				continue;
			}

			consume();
		}

		return nodes;
	}

	function resolveNode():Expr {
		final curToken = currentToken();

		switch (curToken) {
			case TKeyword(keyword, _):
				switch (keyword) {
					case VAR:
						return parseVarDecl();
					case FUNCTION:
						return parseFuncDecl();
					case FOR:
						return parseForStat();
					case WHILE:
						return parseWhileStat();
					case IF:
						return parseIfStat();
					default:
				}
			default:
		}

		final expr = parseExpr();

		if (matchSym(Semicolon))
			consume();

		return expr;

		// throw new LiteException('Unexpected token: ${curToken}');
	}

	// declarations
	function parseVarDecl():Expr {
		expectKeyword(VAR);

		final name = expectIdent().getParameters()[0];

		expectOp(Assign);

		final expr = parseExpr();

		expectSymbol(Semicolon);

		return {
			expr: EVarDecl(name, expr)
		};
	}

	function parseFuncDecl():Expr {
		expectKeyword(FUNCTION);

		final name = expectIdent().getParameters()[0];

		expectSymbol(LParen);

		var params:Array<FArgument> = [];
		while (!matchSym(RParen)) {
			final paramToken = expectIdent();
			params.push({
				name: paramToken.getParameters()[0]
			});

			if (matchSym(Comma))
				consume();
		}

		expectSymbol(RParen);

		final block = parseBlock();

		return {
			expr: EFuncDecl(name, params, block)
		};
	}

	// statements
	function parseWhileStat():Expr {
		consume();

		expectSymbol(LParen);

		final cond = parseExpr();

		expectSymbol(RParen);

		final body = parseBlock();

		return {
			expr: EWhile(cond, body)
		};
	}

	function parseForStat():Expr {
		consume(); // for

		expectSymbol(LParen);

		final fToken = currentToken();

		switch (fToken) {
			case TKeyword(kw, _):
				if (kw == VAR)
					return _parseForCond(true);
			case TIdent(name, pos):
				// check if its cond
				var isCond = false;

				switch (peek()) {
					case TSymbol(sym, _):
						if (sym == Semicolon) isCond = true;
					case TOperator(op, _):
						if (op == Assign) isCond = true;
					case _:
				}

				if (isCond)
					return _parseForCond(false);
			case _:
		}

		return _parseForIn();
	}

	function _parseForCond(isDecl):Expr {
		final decl = isDecl ? parseVarDecl() : parseExpr();
		if (!isDecl)
			expectSymbol(Semicolon);

		final cond = parseExpr();
		expectSymbol(Semicolon);
		final incr = parseExpr();
		expectSymbol(RParen);
		final body = parseBlock();

		return {
			expr: EForCond(decl, cond, incr, body)
		};
	}

	function _parseForIn():Expr {
		final ident = expectIdent().getParameters()[0];

		expectKeyword(IN);

		final iterable = parseExpr();
		expectSymbol(RParen);
		final body = parseBlock();

		return {
			expr: EForIn(ident, iterable, body)
		};
	}

	// TODO: stack of elifs, else
	function parseIfStat():Expr {
		consume();

		expectSymbol(LParen);

		final cond = parseExpr();

		expectSymbol(RParen);

		final body = parseBlock();

		return {
			expr: EIfStat(cond, body)
		};
	}

	function parseBlock():Expr {
		expectSymbol(LBrace);

		var statements = [];
		while (currentToken() != TEof && !matchSym(RBrace)) {
			final stmt = resolveNode();
			if (stmt != null) {
				statements.push(stmt);
			} else {
				throw currentToken();
			}
		}

		expectSymbol(RBrace);

		return {
			expr: EBlock(statements)
		};
	}

	// inicio de parsers de precendencia (TODO: and, or)
	// inicia el arbol de cualquier expresion
	function parseExpr() {
		return parseRange();
	}

	function parseRange():Expr {
		final left = parseAssignment();

		if (matchOp(RangeDot)) {
			consume();
			final right = parseAssignment();

			return {
				expr: ERange(left, right)
			};
		}
		return left;
	}

	function parseAssignment():Expr {
		var left = parseEquality();

		// if we find "=" is an assign
		switch (currentToken()) {
			case TOperator(op, _):
				if (op == Assign) {
					consume();

					final value = parseAssignment();

					switch (left.expr) {
						case EIdent(name):
							return {
								expr: EAssign(name, value)
							};
						default:
							throw new LiteException("Invalid left-hand side in assignment: " + Std.string(left));
					}
				}
			default:
		}

		return left;
	}

	// parsea operadores de igualdad
	// como == o !=
	function parseEquality():Expr {
		var left = parseComparison();

		while (true) {
			switch (currentToken()) {
				case TOperator(op, _):
					switch (op) {
						case Equal, NotEqual:
							consume();

							final right = parseComparison();
							left = {
								expr: EBinOp(left, right, op)
							};
						default:
							return left;
					}
				default:
					return left;
			}
		}
	}

	// parsea comparaciones
	// <, >, >=, <=
	function parseComparison():Expr {
		var left = parseTerm();

		while (true) {
			switch (currentToken()) {
				case TOperator(op, _):
					switch (op) {
						case GreaterThan, GreaterEqualThan, LessThan, LessEqualThan:
							consume();
							final right = parseTerm();
							left = {
								expr: EBinOp(left, right, op)
							};
						default:
							return left;
					}
				default:
					return left;
			}
		}
	}

	// parsea suma y rsta
	function parseTerm():Expr {
		var left = parseFactor();

		while (true) {
			switch (currentToken()) {
				case TOperator(op, _):
					switch (op) {
						case Add, Sub:
							consume();
							final right = parseFactor();
							left = {
								expr: EBinOp(left, right, op)
							}
						default:
							return left;
					}
				default:
					return left;
			}
		}
	}

	// parsea multipliccion division y modulo
	function parseFactor():Expr {
		var left = parseUnary();

		while (true) {
			switch (currentToken()) {
				case TOperator(op, _):
					switch (op) {
						case Mult, Div, Mod:
							consume();
							final right = parseUnary();

							left = {
								expr: EBinOp(left, right, op)
							};
						default:
							return left;
					}
				default:
					return left;
			}
		}
	}

	// parsea unarios
	// !x, +x, ++x, -x, --x
	// TODO: postfijo (x++, x--)
	function parseUnary():Expr {
		switch (currentToken()) {
			case TOperator(op, _):
				switch (op) {
					case Not, Add, AddIncrement, Sub, SubDecrement:
						consume();
						final left = parseUnary();

						return {
							expr: EUnaryOp(left, op)
						};
					default:
				}
			default:
		}
		return parsePrimary();
	}

	// parsea primarios
	// que son literales (strings, numeros, bools, null), idents
	function parsePrimary():Expr {
		switch (currentToken()) {
			case TLiteral(literal, _):
				consume();

				return {
					expr: ELiteral(literal)
				};

			case TIdent(name, _):
				consume();
				return {
					expr: EIdent(name)
				};

			case TSymbol(sym, _):
				if (sym == LParen) {
					consume();

					final expr = parseExpr();

					expectSymbol(RParen);

					return expr;
				}

				throw new LiteException("Unexpected symbol in expression: " + Std.string(currentToken()));
			case TEof:
				return null;

			default:
				throw new LiteException("Unexpected token in expression: " + Std.string(currentToken()));
		}
		throw new LiteException("Unexpected error in primary parsing");
	}

	// final de parsers de precendencia

	function matchSym(matchingSym:Symbol) {
		switch (currentToken()) {
			case TSymbol(sym, _):
				if (sym == matchingSym)
					return true;
			default:
		}

		return false;
	}

	function matchOp(matchingOp:Operator) {
		switch (currentToken()) {
			case TOperator(op, _):
				if (op == matchingOp)
					return true;
			default:
		}

		return false;
	}

	function expectSymbol(eSym:Symbol):Token {
		switch (currentToken()) {
			case TSymbol(sym, _):
				if (sym != eSym)
					throw new LiteException('Expected symbol \"$eSym\" but got ${Std.string(currentToken())}');

				return consume();
			default:
				throw new LiteException("Expected symbol but got " + Std.string(currentToken()));
		}
	}

	function expectKeyword(expectedKw:Keyword):Token {
		switch (currentToken()) {
			case TKeyword(kw, _):
				if (kw != expectedKw)
					throw new LiteException('Expected operator \"$expectedKw\" but got ${Std.string(currentToken())}');

				return consume();
			default:
				throw new LiteException("Expected operator but got " + Std.string(currentToken()));
		}
	}

	function expectOp(expectedOp:Operator):Token {
		switch (currentToken()) {
			case TOperator(op, _):
				if (op != expectedOp)
					throw new LiteException('Expected operator \"$expectedOp\" but got ${Std.string(currentToken())}');

				return consume();
			default:
				throw new LiteException("Expected operator but got " + Std.string(currentToken()));
		}
	}

	function expectIdent():Token {
		switch (currentToken()) {
			case TIdent(name, _):
				return consume();
			default:
				throw new LiteException("Expected identifier but got " + Std.string(peek()));
		}
	}

	function currentToken():Token {
		if (position >= tokens.length) {
			return TEof;
		}
		return tokens[position];
	}

	// uhh works as array.shift lol
	function consume() {
		final cur = currentToken();
		position++;
		return cur;
	}

	function peek(offset:Int = 1) {
		return tokens[position + offset];
	}

	// bottom utils
	function getPrecedence(tok:Token):Int {
		return switch (tok) {
			case TOperator(op, _):
				return switch (op) {
					case Mult, Div, Mod: 3;
					case Add, Sub: 2;
					case Equal, NotEqual: 1;
					case And: 0;
					case Or: -1;
					default: -2;
				}
			default:
				-2;
		}
	}
}
