package;

import haxe.Timer;
import lite.Interp;
import lite.Lexer;
import lite.Parser;
import sys.io.File;

class Main {
	static function main() {
		final c = File.getContent(Sys.getCwd() + 'test/script.lite');
		var time = Timer.stamp();
		var tokens = new Lexer(c).run();
		var parser = new Parser(tokens);
		var ast = parser.run();
		trace(ast);
		var output = new Interp(ast);
		output.run();

		trace(Timer.stamp() - time);
	}
}
