package lite;

import haxe.ds.StringMap;
import haxe.ds.Vector;
import lite.Expr.EscapeType;
import lite.Expr.ExprType;
import lite.Token.Operator;
import lite.core.LiteException;
import lite.core.PosException;
import lite.core.PosInfo;
import lite.interp.LiteValue;
import lite.interp.Scope;
import lite.util.Util;

using lite.util.RuntimeUtil;

class Interp {
	// variable/function storage
	var global:Scope;
	var env:Scope;

	var ast:Vector<Expr>;

	public function new(ast:Array<Expr>) {
		// faster
		#if cpp
		this.ast = Vector.fromData(cast ast);
		#else
		this.ast = Vector.fromArrayCopy(ast);
		#end

		env = new Scope();
		global = env;

		// declare global fields
		global.set("print", VNativeFun((args) -> {
			var thing = args[0];

			Util.print(curPosition, thing.toString());

			return VVoid;
		}));

		global.set("self", VScope(global));
	}

	var ptr = 0;
	var curPosition:PosInfo;

	public function run():String {
		ptr = 0;

		while (ptr < ast.length) {
			var expr = ast[ptr];
			consume();

			eval(expr);
		}
		return null;
	}

	// just for debugging
	var depth = 0;

	function getFrom(object:LiteValue, field:String):LiteValue {
		switch (object) {
			case VScope(s):
				return s.get(field);
			case _:
				return VNull;
		}
		return VNull;
	}

	function evalCond(condition:Expr, body:Expr):LiteValue {
		var condRes = eval(condition);

		switch (condRes) {
			case VBool(v):
				if (v)
					return eval(body);
				return VNull;
			case _:
				return VNull;
		}
	}

	function eval(expr:Expr):LiteValue {
		curPosition = expr.pos;

		switch (expr.expr) {
			// TODO: escapes, tengo una vaga idea en mi cabeza de como, queee es usando excepciones
			case EEscape(kind):
				switch (kind) {
					case Return(expr):
						var v = expr != null ? eval(expr) : VNull;
						throw new Escape(_EscapeType.Return(v));

					case Break:
						throw new Escape(_EscapeType.Break);

					case Continue:
						throw new Escape(_EscapeType.Continue);
				}

			case EIfStat(cond, then, fallback):
				final result = evalCond(cond, then);

				if (result == VNull) {
					if (fallback != null)
						return eval(fallback);
					return result;
				}
				return result;
			case EField(object, field):
				var e = eval(object);
				return getFrom(e, field);

			case EAssign(ident, value):
				final val = eval(value);
				final res = env.assign(ident, val);

				if (res == null)
					throw new PosException('Unknown identifier \"$ident\"', curPosition);

				return val;
			case EBlock(exprs):
				return evalBlock(exprs);

			case EFuncDecl(name, params, body):
				var f:RuntimeFun = {
					name: name,
					args: [for (p in params) VString(p.name)],
					body: body,
					env: env
				};

				// ts is confusing
				var fun = VFun(f);
				env.set(name, fun);

				return fun;
			case EBinOp(left, right, op):
				return evalBinOp(op, left, right);
			case EVarDecl(ident, expr):
				final val = eval(expr);

				return env.set(ident, val);
			case ECall(fun, args):
				var func = eval(fun);
				var argValues = [for (a in args) eval(a)];
				return callFunction(func, argValues);
			case EIdent(ident):
				final n = env.get(ident);

				if (n == null)
					throw new LiteException('Unknown identifier \"$ident\"');
				return n;
			// primitives ig
			case ELiteral(lit):
				return switch (lit) {
					case INT(v): VInt(v);
					case FLOAT(v): VFloat(v);
					case STRING(v): VString(v);
					case BOOL(v): VBool(v);
					case NULL: VNull;
				};
			case _:
				return VNull;
		}
		return VNull;
	}

	function evalBinOp(op:Operator, left:Expr, right:Expr):LiteValue {
		final l = eval(left);
		final r = eval(right);

		// TODO: añadir las ops que quedan
		return switch (op) {
			case Add:
				computeMath(l, r, (a, b) -> a + b, (a, b) -> a + b, (a, b) -> a + b);
			case Sub:
				computeMath(l, r, (a, b) -> a - b, (a, b) -> a - b, null);
			case Mult:
				computeMath(l, r, (a, b) -> a * b, (a, b) -> a * b, null);
			case Div:
				computeMath(l, r, null, (a, b) -> a / b, null);

			case Equal:
				compare(l, r);

			case _:
				throw 'Unsupported binary op: $op';
		}
	}

	function compare(left:LiteValue, right:LiteValue):LiteValue {
		return switch [left, right] {
			case [VInt(a), VInt(b)]: VBool(a == b);
			case [VFloat(a), VFloat(b)]: VBool(a == b);
			case [VBool(a), VBool(b)]: VBool(a == b);
			case [VString(a), VString(b)]: VBool(a == b);

			case [VInt(a), VFloat(b)]: VBool(a == b);
			case [VFloat(a), VInt(b)]: VBool(a == b);

			case [VNull, VNull]: VBool(true);
			case [VNull, _] | [_, VNull]: VBool(false);

			// TODO: comparacion de memoria

			case _: VBool(false);
		}
	}

	// TODO: rehacer esto?? no me gusta como funciona pero lo dejare temporalmente
	function computeMath(l:LiteValue, r:LiteValue, intOp:Null<(Int, Int) -> Int>, floatOp:(Float, Float) -> Float,
			stringOp:Null<(String, String) -> String>):LiteValue {
		return switch [l, r] {
			case [VInt(a), VInt(b)]:
				if (intOp != null) {
					VInt(intOp(a, b));
				} else {
					VFloat(floatOp(a, b));
				}
			case [VFloat(a), VFloat(b)]:
				VFloat(floatOp(a, b));
			case [VInt(a), VFloat(b)]:
				VFloat(floatOp(a, b));
			case [VFloat(a), VInt(b)]:
				VFloat(floatOp(a, b));
			case [VString(a), VString(b)] if (stringOp != null):
				VString(stringOp(a, b));
			case _:
				throw 'Invalid operands for math operation';
		}
	}

	// maybe?
	function callFunction(func:LiteValue, args:Array<LiteValue>):LiteValue {
		return switch (func) {
			case VNativeFun(f):
				f(args);

			case VFun(f):
				var localScope = new Scope(f.env);

				if (f.args.length != args.length)
					throw new LiteException('Expected ${f.args.length} but got ${args.length} arguments');
				// link params (is this how it works?? lol)
				for (i in 0...f.args.length) {
					var argName = switch (f.args[i]) {
						case VString(s): s;
						case _: "arg" + i;
					};
					localScope.set(argName, args[i]);
				}

				// again lololololo
				var prev = env;
				env = localScope;
				var result = eval(f.body);
				env = prev;

				return result;

			case _:
				throw "Trying to call non-function value";
		}
	}

	function evalBlock(exprs:Array<Expr>):LiteValue {
		var funScope = new Scope(env);
		var prev = env;
		env = funScope;

		var last:LiteValue = VNull;

		// fuck fuck fuck fcuk
		for (expr in exprs)
			last = eval(expr);

		env = prev;
		return last;
	}

	function consume() {
		ptr++;
	}
}

private class Escape {
	public var e:_EscapeType;

	public function new(e) {
		this.e = e;
	}
}

enum _EscapeType {
	Return(value:LiteValue);
	Break;
	Continue;
}
