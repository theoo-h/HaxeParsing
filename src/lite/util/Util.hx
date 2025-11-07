package lite.util;

import lite.core.PosInfo;

class Util {
	public static function resolveEnum<T:Enum<T>>(myEnumInstance:T):T {
		return myEnumInstance;
	}

	public static function print(pos:PosInfo, value:Dynamic) {
		var _ = (a:UInt, b:UInt) -> a == b ? Std.string(a) : Std.string(a) + '-' + Std.string(b);
		Sys.println('${pos.file}.lite:${_(pos.start.line, pos.end.line)}: $value');
	}
}
