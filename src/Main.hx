package;

import lite.Interp;
import lite.Lexer;
import lite.Parser;
import sys.io.File;

class Main {
	static function main() {
		var tokens = new Lexer(File.getContent(Sys.getCwd() + 'test/script.lite')).run();
		var parser = new Parser(tokens);
		var ast = parser.run();
		var output = new Interp(ast);
		output.run();
	}
}
