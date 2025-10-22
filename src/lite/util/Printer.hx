package lite.util;

import lite.Expr;

using StringTools;

class Printer {
	public static inline var spcPerIdn:Int = 4;

	static inline function indentStr(n:Int):String {
		return StringTools.lpad("", " ", n * spcPerIdn);
	}

	public static function run(nodes) {
		return nodes.map(node -> print(node, 0)).join("\n");
	}

	public static function print(node, level) {
		if (node == null)
			return indentStr(level) + "null";
		final pad = indentStr(level);

		switch (node.expr) {
			case EVarDecl(name, value):
				return pad + 'EVarDecl(' + name + ', ' + format(value, level) + '\n' + pad + ')';

			case EFuncDecl(name, params, block):
				var ps = params.map(p -> p.name).join(", ");
				return pad + 'EFuncDecl(' + name + ', [' + ps + '], ' + format(block, level) + '\n' + pad + ')';

			case EBlock(exprs):
				var inner = exprs.map(e -> print(e, level + 1)).join("\n");
				return pad + 'EBlock(\n' + inner + '\n' + pad + ')';

			case EAssign(name, value):
				return pad + 'EAssign(' + name + ', ' + format(value, level) + '\n' + pad + ')';

			case EBinOp(left, right, op):
				var leftStr = format(left, level);
				var rightStr = format(right, level);
				return pad + 'EBinOp(' + op + ', ' + leftStr + ', ' + rightStr + '\n' + pad + ')';

			case EUnaryOp(expr, op):
				return pad + 'EUnaryOp(' + op + ', ' + format(expr, level) + '\n' + pad + ')';

			case EIdent(name):
				return pad + 'EIdent(' + name + ')';

			case ELiteral(lit):
				return pad + 'ELiteral(' + Std.string(lit) + ')';

			default:
				return pad + 'Unknown(' + Std.string(node) + ')';
		}
	}

	static function format(expr:Expr, level:Int):String {
		if (expr == null)
			return "null";
		switch (expr.expr) {
			case EIdent(_), ELiteral(_):
				return Std.string(print(expr, 0)).trim();
			default:
				return '\n' + print(expr, level + 1);
		}
	}
}
