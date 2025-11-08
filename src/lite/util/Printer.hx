package lite.util;

import lite.Expr;

// esta clase es una mierda
class Printer {
	public static inline var spcPerIdn:Int = 4;

	public static function print(node:Expr):String {
		return switch (node.expr) {
			case EAssign(ident, value):
				'$ident = ${print(value)}';
			case ELiteral(literal):
				switch (literal) {
					case INT(value):
						Std.string(value);
					case STRING(value):
						'"$value"';
					case FLOAT(value):
						Std.string(value);
					case BOOL(value):
						Std.string(value);
					case NULL:
						"null";
				}
			case _: 'unknown';
		};
	}
}
