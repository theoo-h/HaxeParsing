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
		trace('Tokenizing...');
		var tokens = new Lexer(c).run();

		trace('Parsing...');
		var parser = new Parser(tokens);
		var ast = parser.run();
		trace('Evaluating...');
		var output = new Interp(ast);
		output.run();
		trace('Time taken (tokenize, parsing and interping): ${Timer.stamp() - time}');
	}
}
