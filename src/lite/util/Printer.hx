package lite.util;

import lite.Expr;

// esta clase es una mierda
class Printer {
	public static inline var spcPerIdn:Int = 4;

	static inline function indentStr(level:Int):String {
		return StringTools.lpad("", " ", level * spcPerIdn);
	}

	public static function run(nodes:Array<Expr>):String {
		return nodes.map(node -> print(node, 0)).join("\n");
	}

	public static function print(node:Expr, level:Int):String {
		if (node == null)
			return indentStr(level) + "null";

		final pad = indentStr(level);
		final end = "\n" + indentStr(level) + ")";

		switch (node.expr) {
			case EIfStat(cond, thenBranch, fallback):
				return pad + "EIfStat(" + format(cond, level + 1) + ",\n" + print(thenBranch, level + 1) + ",\n" + print(fallback, level + 1) + "\n" + pad
					+ ")" + end;

			case EWhile(condition, body):
				return pad + "EWhile(" + format(condition, level + 1) + ",\n" + print(body, level + 1) + "\n" + pad + ")" + end;

			case EVarDecl(name, value):
				return pad + "EVarDecl(" + name + ", " + format(value, level) + ")";

			case EAssign(name, value):
				return pad + "EAssign(" + name + ", " + format(value, level) + ")";

			case EBinOp(left, right, op):
				return pad + "EBinOp(" + op + ", " + format(left, level + 1) + ", " + format(right, level + 1) + ")";

			case EUnaryOp(expr, op):
				return pad + "EUnaryOp(" + op + ", " + format(expr, level + 1) + ")";

			case ELiteral(lit):
				return pad + "ELiteral(" + Std.string(lit) + ")";

			case EIdent(name):
				return pad + "EIdent(" + name + ")";

			case EBlock(exprs):
				if (exprs.length == 0)
					return pad + "EBlock([])";
				var inner = exprs.map(e -> print(e, level + 1)).join("\n");
				return pad + "EBlock(\n" + inner + "\n" + pad + ")" + end;

			case EFuncDecl(name, params, body):
				var ps = params.map(p -> p.name).join(", ");
				return pad + "EFuncDecl(" + name + ", [" + ps + "],\n" + print(body, level + 1) + "\n" + pad + ")" + end;

			case EForCond(init, cond, incr, body):
				return pad + "EForCond(" + format(init, level + 1) + ", " + format(cond, level + 1) + ", " + format(incr, level + 1) + ",\n"
					+ print(body, level + 1) + "\n" + pad + ")" + end;

			case EForIn(ident, iterable, body):
				return pad + "EForIn(" + ident + ", " + format(iterable, level + 1) + ",\n" + print(body, level + 1) + "\n" + pad + ")" + end;

			case ERange(min, max):
				return pad + "ERange(" + format(min, level + 1) + ", " + format(max, level + 1) + ")" + end;

			case EEof:
				return pad + "EEof";

			case EField(obj, field):
				return pad + "EField(" + format(obj, level + 1) + ", " + field + ")" + end;

			case ECall(func, args):
				if (args.length == 0)
					return pad + "ECall(" + format(func, level + 1) + ", [])";
				var argsStr = args.map(a -> format(a, level + 1)).join(", ");
				return pad + "ECall(" + format(func, level + 1) + ", [" + argsStr + "])" + end;

			default:
				return pad + "Unknown(" + Std.string(node) + ")" + end;
		}
	}

	static function format(expr:Expr, level:Int):String {
		if (expr == null)
			return "null";

		switch (expr.expr) {
			case EIdent(_), ELiteral(_):
				// simple nodes inline
				return Std.string(print(expr, 0));
			default:
				// complex nodes indented
				return "\n" + print(expr, level);
		}
	}
}
