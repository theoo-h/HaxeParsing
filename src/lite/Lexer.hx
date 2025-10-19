package lite;

import lite.Token;
import lite.core.PosException;

class Lexer {
	var content:String;

	public function new(content:String) {
		this.content = content;
	}

	var line:UInt;
	var column:UInt;

	var position:UInt;

	public function run():Array<Token> {
		final tokens:Array<Token> = [];

		line = 1;
		column = 0;

		position = 0;

		while (position < content.length) {
			final token:Token = resolveToken();

			if (token != null)
				tokens.push(token);

			consume();
		}
		return tokens;
	}

	function resolveToken():Null<Token> {
		final char = currentChar();

		switch (char) {
			case isWhitespace(char) => true:
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

		final position:Position = {};

		position.minLine = line;
		position.minColumn = column;

		// consume the delimiter
		consume();

		while (true) {
			final char = currentChar();

			if (char == delimiter)
				break;

			if (StringTools.isEof(char)) {
				position.maxLine = line;
				position.maxColumn = column;

				throw new PosException("Expected \"", position);
			}

			buff.addChar(char);

			consume();
		}

		position.maxLine = line;
		position.maxColumn = column;

		return TLiteral(STRING(buff.toString()), position);
	}

	function parseSymbol():Token {
		final char = currentChar();
		final position:Position = {};

		position.minLine = line;
		position.minColumn = column;

		final sym:Null<Symbol> = switch (char) {
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
			case _:
				null;
		}
		final op:Null<Operator> = switch (char) {
			case "=".code:
				if (peek() == "=".code) {
					consume();
					EQUAL;
				} else ASSIGN;

			case "+".code:
				if (peek() == '+'.code) {
					consume();
					ADD_INCREMENT;
				} else if (peek() == '='.code) {
					consume();
					ADD_ASSIGN;
				} else ADD;

			case "-".code:
				if (peek() == '-'.code) {
					consume();
					SUB_DECREMENT;
				} else if (peek() == '='.code) {
					consume();
					SUB_ASSIGN;
				} else SUB;

			case "*".code:
				if (peek() == '='.code) {
					consume();
					MULT_ASSIGN;
				} else MULT;
			case _:
				null;
		}

		position.maxLine = line;
		position.maxColumn = column;

		if (sym != null)
			return TSymbol(sym, position);

		if (op != null)
			return TOperator(op, position);

		return null;
	}

	function parseNumber():Token {
		var buff:StringBuf = new StringBuf();
		var position:Position = {};

		position.minLine = line;
		position.minColumn = column;

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
			position.maxLine = line;
			position.maxColumn = column;
			return TLiteral(INT(Std.parseInt(buff.toString())), position);
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

		position.maxLine = line;
		position.maxColumn = column;

		var str = buff.toString();
		if (isFloat)
			return TLiteral(FLOAT(Std.parseFloat(str)), position);
		else
			return TLiteral(INT(Std.parseInt(str)), position);
	}

	function parseIdent() {
		final buff:StringBuf = new StringBuf();
		final position:Position = {};

		position.minLine = line;
		position.minColumn = column;

		while (true) {
			final char = currentChar();

			if (StringTools.isEof(char) || (char != "_".code && !isAlpha(char)) || isWhitespace(char))
				break;

			buff.addChar(char);

			consume();
		}
		position.maxLine = line;
		position.maxColumn = column;

		final output = buff.toString();

		// tries to resolve keyword
		final possibleKeyword = resolveKeyword(output);

		if (possibleKeyword != null)
			return TKeyword(possibleKeyword, position);

		// tries to resolve literal
		final possibleLiteral = resolveLiteral(output);

		if (possibleLiteral != null)
			return TLiteral(possibleLiteral, position);

		return TIdent(output, position);
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
	}

	function peek() {
		return StringTools.fastCodeAt(content, position + 1);
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
