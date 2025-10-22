package;

import lite.Lexer;
import lite.Parser;
import lite.Token;
import lite.core.PosInfo;

class Main {
	static function main() {
		var tokens = new Lexer("10 + (20 * (20.5 / 56))").run();
		var parser = new Parser(tokens);
		var ast = parser.run();

		for (tree in ast)
			trace(tree);
	}
}
