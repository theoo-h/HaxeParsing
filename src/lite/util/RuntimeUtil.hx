package lite.util;

import lite.interp.LiteValue;

class RuntimeUtil {
	public static function toString(v:LiteValue):String {
		return switch (v) {
			case VInt(n): Std.string(n);
			case VScope(s): @:privateAccess s._.toString();
			case VFloat(n): Std.string(n);
			case VBool(b): b ? "true" : "false";
			case VString(s): s;
			case VArray(arr): "[" + arr.map(toString).join(", ") + "]";
			case VNull: "null";
			case VFun(_): "<function>";
			case VNativeFun(_): "<native function>";
			case VVoid: "void";
		}
	}
}
