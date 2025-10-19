package;

import lite.Lexer;

class Main {
	static function main() {
		var lexer = new Lexer("
		var myVariable = 0xFFFFFFF;
		
		var myOtherVariable = myVariable + 10.6;

		function main()
		{
			print(\"This is great !\");

			myOtherVariable++;
		}
		");

		trace(lexer.run());
	}
}
