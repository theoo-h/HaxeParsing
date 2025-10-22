package;

import lite.Lexer;
import lite.Parser;
import lite.Token;
import lite.util.Printer;

class Main {
	static function main() {
		var tokens = new Lexer('
		var i = 1;

		for (i; i < 5; ++i) {}
		for (i = 0; i < 5 / (10 * 16); ++i) {}

		for (var i = 0; i < 11; ++i) {}

		for (i in 0...10) {}

		while ((5 * 16 / 5.545e+3 / (10 * 5.5)) < 3) {}

		if (true == false) {}

		').run();
		var parser = new Parser(tokens);
		var ast = parser.run();
		trace("\n" + Printer.run(ast));
	}
}
