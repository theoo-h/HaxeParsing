package lite;

import haxe.ds.StringMap;
import haxe.ds.Vector;
import lite.Expr.EscapeType;
import lite.Expr.ExprType;
import lite.Expr.StructDef;
import lite.Token.Operator;
import lite.core.LiteException;
import lite.core.PosException;
import lite.core.PosInfo;
import lite.interp.LiteValue;
import lite.interp.Scope;
import lite.util.Printer;
import lite.util.Util;

using lite.util.RuntimeUtil;

// https://haxe.org/manual/lf-pattern-matching-tuples.html
// HAXE HAD TUPLES ALL THIS TIME???
class Interp {
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

		scopePool = new Vector<Null<Scope>>(Std.int(Math.pow(2, 12)), null);
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
			// case VInst(ref):
			// 	final field = ref.fields.get(field);

			// 	if (field == null) {
			// 		throw new PosException('Unknown identifier "$field "in object "$object"', curPosition);
			// 	}
			// 	return field;
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

	function createStruct(def) {
		return null;
	}

	function eval(expr:Expr):LiteValue {
		curPosition = expr.pos;

		switch (expr.expr) {
			case EArrayAccess(object, index):
				final vobj = eval(object);
				final vindex = eval(index);

				var idxn = -1;

				switch (vindex) {
					case VInt(v):
						idxn = v;
					case _:
						throw new PosException('Invalid index ${Printer.print(index)} for array access', curPosition);
				}
				switch (vobj) {
					case VArray(v):
						return v[idxn];
					case _:
						throw new PosException('Object ${Printer.print(object)} has not array access.', curPosition);
				}
			case EArray(mem):
				return VArray([for (m in mem) eval(m)]);
			case EStructDecl(def):
				return createStruct(def);

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

			case EWhile(condition, body):
				while (true) {
					try {
						var condRes = evalCond(condition, body);
						if (condRes == VNull)
							break;
					} catch (e:Escape) {
						switch (e.e) {
							case Break:
								break;
							case Continue:
								continue;
							case Return(_):
								throw e;
						}
					}
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
					throw new PosException('Unknown identifier \"$ident\" for assign', curPosition);

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

				switch (func) {
					// case VStruct(f):
					// 	return createInstance(f, argValues);
					case _:
						return callFunction(func, argValues);
				}

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

		return switch (op) {
			case Add:
				computeMath(l, r, (a, b) -> a + b, (a, b) -> a + b, (a, b) -> a + b);
			case Sub:
				computeMath(l, r, (a, b) -> a - b, (a, b) -> a - b, null);
			case Mult:
				computeMath(l, r, (a, b) -> a * b, (a, b) -> a * b, null);
			case Div:
				computeMath(l, r, null, (a, b) -> a / b, null);
			case Mod:
				computeMath(l, r, (a, b) -> a % b, (a, b) -> a % b, null);

			case Equal, LessThan, LessEqualThan, GreaterThan, GreaterEqualThan:
				compare(l, r, op);

			case _:
				throw 'Unsupported binary op: $op';
		}
	}

	function compare(left:LiteValue, right:LiteValue, ?op:Operator):LiteValue {
		return switch [left, right] {
			// numeric comparisons
			case [VInt(a), VInt(b)]:
				switch op {
					case Equal: VBool(a == b);
					case LessThan: VBool(a < b);
					case LessEqualThan: VBool(a <= b);
					case GreaterThan: VBool(a > b);
					case GreaterEqualThan: VBool(a >= b);
					case _: VBool(false);
				}

			case [VFloat(a), VFloat(b)]:
				switch op {
					case Equal: VBool(a == b);
					case LessThan: VBool(a < b);
					case LessEqualThan: VBool(a <= b);
					case GreaterThan: VBool(a > b);
					case GreaterEqualThan: VBool(a >= b);
					case _: VBool(false);
				}

			case [VInt(a), VFloat(b)]:
				switch op {
					case Equal: VBool(a == b);
					case LessThan: VBool(a < b);
					case LessEqualThan: VBool(a <= b);
					case GreaterThan: VBool(a > b);
					case GreaterEqualThan: VBool(a >= b);
					case _: VBool(false);
				}

			case [VFloat(a), VInt(b)]:
				switch op {
					case Equal: VBool(a == b);
					case LessThan: VBool(a < b);
					case LessEqualThan: VBool(a <= b);
					case GreaterThan: VBool(a > b);
					case GreaterEqualThan: VBool(a >= b);
					case _: VBool(false);
				}

			// other types
			case [VBool(a), VBool(b)]:
				VBool(op == Equal && a == b);
			case [VString(a), VString(b)]:
				VBool(op == Equal && a == b);

			case [VNull, VNull]:
				VBool(op == Equal);
			case [VNull, _] | [_, VNull]:
				VBool(false);

			case _:
				VBool(false);
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

				for (i in 0...f.args.length) {
					var argName = switch (f.args[i]) {
						case VString(s): s;
						case _: "arg" + i;
					};
					localScope.set(argName, args[i]);
				}

				var prev = env;
				env = localScope;

				var result:LiteValue;
				try {
					result = eval(f.body);
				} catch (e:Escape) {
					switch (e.e) {
						case Return(v):
							result = v;
						case Break, Continue:
							throw new LiteException("Break/Continue outside loop");
					}
				}

				env = prev;
				return result;

			case _:
				throw "Trying to call non-function value " + func;
		}
	}

	function evalBlock(exprs:Array<Expr>):LiteValue {
		var funScope = new Scope(env);
		var prev = env;
		env = funScope;

		var last:LiteValue = VNull;

		try {
			for (expr in exprs) {
				last = eval(expr);
			}
		} catch (e:Escape) {
			env = prev;

			// recursivigod
			throw e;
		}

		env = prev;
		return last;
	}

	function consume() {
		ptr++;
	}

	// internal stuff
	// variable/function storage
	var scopePool:Vector<Null<Scope>>;

	inline function allocScope(parent:Scope):Scope {
		for (i in 0...scopePool.length) {
			var s = scopePool[i];
			if (s != null && !s.inUse) {
				s.reset(parent);
				s.inUse = true;
				return s;
			}
		}
		var s = new Scope(parent);
		s.inUse = true;
		return s;
	}

	inline function freeScope(s:Scope) {
		s.clear();
		s.inUse = false;
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
