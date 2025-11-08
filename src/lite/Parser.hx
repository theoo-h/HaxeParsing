package lite;

import haxe.Template;
import lite.Expr;
import lite.Token;
import lite.Token;
import lite.core.LiteException;
import lite.core.PosException;
import lite.core.PosInfo;

using lite.util.Printer;

private enum ContextType {
	Global;
	Struct;
	Function;
	Block;
}

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
					case RETURN:
						return parseReturn();
					case BREAK:
						return {
							expr: EEscape(Break),
							pos: currentPos()
						};
					case CONTINUE:
						return {
							expr: EEscape(Break),
							pos: currentPos()
						};
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
					case STRUCT:
						return parseStruct();
					default:
				}
			default:
		}

		final expr = parseExpr();

		if (matchSym(Semicolon))
			consume();

		if (expr != null && !allowInContext(expr)) {
			throw new PosException('Invalid statement in struct body: `${expr.print()}` ', currentPos());
		}

		return expr;

		// throw new LiteException('Unexpected token: ${curToken}');
	}

	function parseStruct():Expr {
		consume();
		final name = expectIdent().getParameters()[0];

		pushCtx(Struct);
		final body = parseBlock();
		popCtx(Struct);

		return {
			expr: EStructDecl(name, body),
			pos: currentPos()
		};
	}

	function parseReturn():Expr {
		consume(); // ret

		final expr = parseExpr();
		expectSymbol(Semicolon);

		return {
			expr: EEscape(Return(expr)),
			pos: currentPos()
		};
	}

	function parseVarDecl():Expr {
		expectKeyword(VAR);

		final name = expectIdent().getParameters()[0];

		expectOp(Assign);

		final expr = parseExpr();

		expectSymbol(Semicolon);

		return {
			expr: EVarDecl(name, expr),
			pos: currentPos()
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

		pushCtx(Function);
		final block = parseBlock();
		popCtx(Function);

		return {
			expr: EFuncDecl(name, params, block),
			pos: currentPos()
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
			expr: EWhile(cond, body),
			pos: currentPos()
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
			expr: EForCond(decl, cond, incr, body),
			pos: currentPos()
		};
	}

	function _parseForIn():Expr {
		final ident = expectIdent().getParameters()[0];

		expectKeyword(IN);

		final iterable = parseExpr();
		expectSymbol(RParen);
		final body = parseBlock();

		return {
			expr: EForIn(ident, iterable, body),
			pos: currentPos()
		};
	}

	// TODO: stack of elifs, else
	function parseIfStat():Expr {
		consume();

		expectSymbol(LParen);

		final cond = parseExpr();

		expectSymbol(RParen);

		final body = parseBlock();

		var fallback:Null<Expr> = null;

		if (matchKw(ELIF)) {
			fallback = parseIfStat();
		} else if (matchKw(ELSE)) {
			consume();

			fallback = parseBlock();
		}

		return {
			expr: EIfStat(cond, body, fallback),
			pos: currentPos()
		};
	}

	function parseBlock():Expr {
		expectSymbol(LBrace);
		pushCtx(Block);

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

		popCtx(Block);

		return {
			expr: EBlock(statements),
			pos: currentPos()
		};
	}

	// inicio de parsers de precendencia (TODO: and, or)
	// inicia el arbol de cualquier expresion
	function parseExpr() {
		return parseOr();
	}

	function parseOr():Expr {
		var left = parseAnd();

		while (true) {
			switch (currentToken()) {
				case TOperator(op, _):
					if (op == Or) {
						consume();
						final right = parseAnd();
						left = {
							expr: EBinOp(left, right, op),
							pos: currentPos()
						};
					} else {
						return left;
					}
				default:
					return left;
			}
		}
	}

	function parseAnd():Expr {
		var left = parseRange();

		while (true) {
			switch (currentToken()) {
				case TOperator(op, _):
					if (op == And) {
						consume();
						final right = parseRange();
						left = {
							expr: EBinOp(left, right, op),
							pos: currentPos()
						};
					} else {
						return left;
					}
				default:
					return left;
			}
		}
	}

	function parseRange():Expr {
		final left = parseAssignment();

		if (matchOp(RangeDot)) {
			consume();
			final right = parseAssignment();

			return {
				expr: ERange(left, right),
				pos: currentPos()
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
								expr: EAssign(name, value),
								pos: currentPos()
							};
						case EField(base, field):
							return {
								expr: EFieldAssign(base, field, value),
								pos: currentPos()
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
								expr: EBinOp(left, right, op),
								pos: currentPos()
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
								expr: EBinOp(left, right, op),
								pos: currentPos()
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
								expr: EBinOp(left, right, op),
								pos: currentPos()
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
								expr: EBinOp(left, right, op),
								pos: currentPos()
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
							expr: EUnaryOp(left, op),
							pos: currentPos()
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
		var expr:Expr;

		switch (currentToken()) {
			case TLiteral(literal, _):
				consume();
				expr = {
					expr: ELiteral(literal),
					pos: currentPos()
				};
			case TIdent(name, _):
				consume();
				expr = {
					expr: EIdent(name),
					pos: currentPos()
				};
			case TSymbol(sym, _):
				if (sym == LParen) {
					consume();
					expr = parseExpr();
					expectSymbol(RParen);
				} else {
					throw new LiteException("Unexpected symbol in primary: " + Std.string(currentToken()));
				}
			case TEof:
				return null;
			default:
				throw new LiteException("Unexpected token in primary: " + Std.string(currentToken()));
		}

		while (true) {
			// call
			if (matchSym(LParen)) {
				consume();
				var args:Array<Expr> = [];
				while (!matchSym(RParen)) {
					args.push(parseExpr());
					if (matchSym(Comma))
						consume();
					else
						break;
				}
				expectSymbol(RParen);
				expr = {
					expr: ECall(expr, args),
					pos: currentPos()
				};
			} else if (matchSym(Dot)) {
				// field access
				consume();
				var fieldName = expectIdent().getParameters()[0];
				expr = {
					expr: EField(expr, fieldName),
					pos: currentPos()
				};
			} else {
				break; // no more postfix
			}
		}

		return expr;
	}

	// final de parsers de precendencia

	function matchKw(matchingKw:Keyword) {
		switch (currentToken()) {
			case TKeyword(kw, _):
				if (kw == matchingKw)
					return true;
			default:
		}

		return false;
	}

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

	function currentPos():PosInfo {
		switch (currentToken()) {
			case TKeyword(_, pos), TIdent(_, pos), TLiteral(_, pos), TOperator(_, pos), TSymbol(_, pos):
				return pos;
			case _:
				return null;
		}
	}

	var ctxStack:Array<ContextType> = [Global];

	private var ctx(get, never):ContextType;

	private function get_ctx():ContextType
		return ctxStack[ctxStack.length - 1];

	private function pushCtx(_:ContextType) {
		ctxStack.push(_);
	}

	private function popCtx(_:ContextType) {
		if (ctxStack.length > 1) // never pop the initial Global
			ctxStack.pop();
		else
			throw new PosException("Parser internal error: popCtx underflow", currentPos());
	}

	private function allowInContext(expr:Expr):Bool {
		// Check if we're inside a function → allow everything
		if (ctxStack.indexOf(ContextType.Function) != -1)
			return true;

		// Otherwise, if we're inside a struct (and NOT inside a function)
		if (ctxStack.indexOf(ContextType.Struct) != -1) {
			return switch (expr.expr) {
				case EVarDecl(_) | EFuncDecl(_) | EStructDecl(_): true;
				default: false;
			}
		}

		// Global / block level → allow everything
		return true;
	}
}
