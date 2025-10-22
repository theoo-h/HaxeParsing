package;

import lite.Lexer;
import lite.Parser;
import lite.Token;
import lite.util.Printer;

class Main {
	static function main() {
		var tokens = new Lexer('
		var myNum = 10;
		var myNum_2 = 20;

		function miFunc() {
			var mySum = 10 + (myNum * myNum_2 / (16 * 4 / (myNum_2)));
			mySum = null;
		}
		').run();
		var parser = new Parser(tokens);
		var ast = parser.run();
		trace(Printer.run(ast));
	}
}
