package;

import lite.Lexer;
import lite.Parser;
import lite.Token;
import lite.util.Printer;

class Main {
	static function main() {
		var tokens = new Lexer('
			function myShit(a, b, c)
			{
				var i = 1;

				for (i; i < 5; ++i) {}
					
				for (i = 0; i < 5 / (10 * 16); ++i) {}

				for (var i = 0; i < 11; ++i) {}
				'
			+ /* FIXME: for (i in 0...10) {}*/ '

				while ((5 * 16 / 5.545e+3 / (10 * 5.5)) < 3) {}

				if (a > 3 || a == 3 && a <= (4 + 5 * 16.5 / (1)))
				{
					var smth = a;
				}
				elif (a < 3)
				{
					var bTwo = b + 2;
				}
				elif (a == 5)
				{
					a = b;
				}
				else {
					c = null;
				}

				c.aField(a, b, c).aFieldFromCall.many(defval = 10, anotherOne = "hellowol", ee = null, aaa);
			}
		').run();
		var parser = new Parser(tokens);
		var ast = parser.run();
		trace("\n" + Printer.run(ast));
	}
}
