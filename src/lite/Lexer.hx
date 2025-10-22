package lite;

import lite.Token;
import lite.core.LiteException;
import lite.core.PosException;
import lite.core.PosInfo;
import lite.util.Util;

// broken somehow
// (( )) <- this one doesnt get parsed, idk why
// FIXME
// rn i will just write tokens myself while making the ast
class Lexer {
	var content:String;

	public function new(content:String) {
		this.content = content;
	}

	var line:UInt;
	var column:UInt;

	var position:UInt;

	var info:PosInfo;

	function prepareInfo() {
		info = {};

		info.minLine = line;
		info.minColumn = column;
	}

	public function run():Array<Token> {
		final tokens:Array<Token> = [];

		line = 1;
		column = 0;

		position = 0;

		prepareInfo();

		while (position < content.length) {
			final token:Token = resolveToken();

			if (token != null)
				tokens.push(token);
		}

		tokens.push(TEof);
		return tokens;
	}

	function resolveToken():Null<Token> {
		final char = currentChar();

		switch (char) {
			case isWhitespace(char) => true:
				consume();
				return null;
			case isDigit(char) => true:
				return parseNumber();
			case isSymbol(char) => true:
				return parseSymbol();

			case "\"".code | "\'".code:
				return parseString(char);

			default:
				return parseIdent();
		}

		return null;
	}

	function parseString(delimiter:Int):Token {
		var buff:StringBuf = new StringBuf();

		prepareInfo();

		// consume the delimiter
		consume();

		while (true) {
			final char = currentChar();

			if (char == delimiter)
				break;

			if (StringTools.isEof(char)) {
				throw new PosException("Expected \"", info);
			}

			buff.addChar(char);

			consume();
		}

		return TLiteral(STRING(buff.toString()), info);
	}

	function parseSymbol():Token {
		final char = currentChar();
		prepareInfo();

		final sym:Null<Symbol> = switch (char) {
			case ",".code:
				Comma;
			case ";".code:
				Semicolon;
			case ":".code:
				Colon;
			case "(".code:
				LParen;
			case ")".code:
				RParen;
			case "[".code:
				LBracket;
			case "]".code:
				RBracket;
			case "{".code:
				LBrace;
			case "}".code:
				RBrace;
			default:
				null;
		}
		final op:Null<Operator> = switch (char) {
			case "%".code:
				Mod;
			case "!".code:
				if (peek() == "=".code) {
					consume();
					NotEqual;
				} else Not;
			case "|".code:
				if (peek() == "|".code) {
					consume();
					Or;
				} else null;
			case "&".code:
				if (peek() == "&".code) {
					consume();
					And;
				} else null;
			case ">".code:
				if (peek() == "=".code) {
					consume();
					GreaterEqualThan;
				} else GreaterThan;
			case "<".code:
				if (peek() == "-".code) {
					consume();
					LArrow;
				} else if (peek() == "=".code) {
					consume();
					LessEqualThan;
				} else LessThan;

			case "=".code:
				if (peek() == "=".code) {
					consume();
					Equal;
				} else Assign;

			case "+".code:
				if (peek() == '+'.code) {
					consume();
					AddIncrement;
				} else if (peek() == '='.code) {
					consume();
					AddAssign;
				} else Add;

			case "/".code:
				Div;
			case "-".code:
				if (peek() == '>'.code) {
					consume();
					RArrow;
				} else if (peek() == '-'.code) {
					consume();
					SubDecrement;
				} else if (peek() == '='.code) {
					consume();
					SubAssign;
				} else Sub;

			case "*".code:
				if (peek() == '='.code) {
					consume();
					MultAssign;
				} else Mult;
			default:
				null;
		}

		if (sym != null) {
			consume();
			return TSymbol(sym, info);
		}
		if (op != null) {
			consume();
			return TOperator(op, info);
		}

		return null;
	}

	function parseNumber():Token {
		var buff:StringBuf = new StringBuf();
		prepareInfo();

		var isFloat = false;

		// check for hex
		if (currentChar() == '0'.code && (peek() == 'x'.code || peek() == 'X'.code)) {
			buff.addChar(currentChar());
			consume();
			buff.addChar(currentChar());
			consume();
			while (isHexDigit(currentChar())) {
				buff.addChar(currentChar());
				consume();
			}
			return TLiteral(INT(Std.parseInt(buff.toString())), info);
		}

		// float
		while (isDigit(currentChar())) {
			buff.addChar(currentChar());
			consume();
		}

		// dec point
		if (currentChar() == '.'.code) {
			isFloat = true;
			buff.addChar(currentChar());
			consume();
			while (isDigit(currentChar())) {
				buff.addChar(currentChar());
				consume();
			}
		}

		// sientific notation
		if (currentChar() == 'e'.code || currentChar() == 'E'.code) {
			isFloat = true;
			buff.addChar(currentChar());
			consume();
			if (currentChar() == '+'.code || currentChar() == '-'.code) {
				buff.addChar(currentChar());
				consume();
			}
			while (isDigit(currentChar())) {
				buff.addChar(currentChar());
				consume();
			}
		}

		var str = buff.toString();
		if (isFloat)
			return TLiteral(FLOAT(Std.parseFloat(str)), info);
		else
			return TLiteral(INT(Std.parseInt(str)), info);
	}

	function parseIdent() {
		final buff:StringBuf = new StringBuf();
		prepareInfo();

		while (true) {
			final char = currentChar();

			// we can also check digit bc atp we also checekd if first char is not digit
			if (StringTools.isEof(char) || (char != "_".code && !isAlpha(char) && !isDigit(char)) || isWhitespace(char))
				break;

			buff.addChar(char);

			consume();
		}

		final output = buff.toString();

		// tries to resolve keyword
		final possibleKeyword = resolveKeyword(output);

		if (possibleKeyword != null)
			return TKeyword(possibleKeyword, info);

		// tries to resolve literal
		final possibleLiteral = resolveLiteral(output);

		if (possibleLiteral != null)
			return TLiteral(possibleLiteral, info);

		return TIdent(output, info);
	}

	function resolveLiteral(name:String):Null<Literal> {
		return switch (name) {
			case "true":
				return BOOL(true);
			case "false":
				return BOOL(false);
			case "null":
				return NULL;
			case _:
				return null;
		}
	}

	function resolveKeyword(name:String):Null<Keyword> {
		return switch (name) {
			case "var": VAR;
			case "function":
				FUNCTION;
			case "if":
				IF;
			case "elif":
				ELIF;
			case "else":
				ELSE;
			case "while":
				WHILE;
			case "for":
				FOR;
			case _:
				null;
		}
	}

	function currentChar() {
		return StringTools.fastCodeAt(content, position);
	}

	function consume() {
		var currentChar:Int = currentChar();

		if (currentChar == '\n'.code) {
			line++;
			column = 1;
		} else
			column++;
		position++;

		info.maxLine = line;
		info.maxColumn = column;
	}

	function peek(offset:Int = 1) {
		return StringTools.fastCodeAt(content, position + offset);
	}

	// helpers
	function isWhitespace(char:Int):Bool {
		return char == ' '.code || char == '\t'.code || char == '\n'.code || char == '\r'.code;
	}

	function isDigit(char:Int) {
		return char >= '0'.code && char <= '9'.code;
	}

	function isHexDigit(char:Int):Bool {
		return (char >= '0'.code && char <= '9'.code) || (char >= 'a'.code && char <= 'f'.code) || (char >= 'A'.code && char <= 'F'.code);
	}

	function isAlpha(char:Int):Bool {
		return (char >= 'a'.code && char <= 'z'.code) || (char >= 'A'.code && char <= 'Z'.code);
	}

	function isSymbol(char:Int):Bool {
		return char == '+'.code || char == '-'.code || char == '*'.code || char == '/'.code || char == '%'.code || char == '='.code || char == '!'.code
			|| char == '<'.code || char == '>'.code || char == '&'.code || char == '|'.code || char == '^'.code || char == '~'.code || char == '('.code
			|| char == ')'.code || char == '['.code || char == ']'.code || char == '{'.code || char == '}'.code || char == ';'.code || char == ':'.code
			|| char == ','.code || char == '.'.code || char == '?'.code;
	}
}
