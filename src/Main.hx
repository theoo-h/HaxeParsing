package;

import lite.Lexer;
import lite.Parser;
import lite.Token;
import lite.core.PosInfo;

class Main {
	static function main() {
		/**
		 * significa:
		 * 10 + (20 * (20.5 / 56))
		 */
		// @formatter:off
		var tokens = [
			TOperator(AddIncrement, null),
			TLiteral(INT(10), null),
			TOperator(Add, null),

			TSymbol(LParen, null),

				TLiteral(INT(20), null),
				TOperator(Mult, null),

				TSymbol(LParen, null),
					TLiteral(FLOAT(20.5), null),
					TOperator(Div, null),
					TLiteral(INT(56), null),
				TSymbol(RParen, null),
			
			TSymbol(RParen, null)
		];
	// @formatter:on
		var parser = new Parser(tokens);
		var ast = parser.run();

		for (tree in ast)
			trace(tree);
	}
}
