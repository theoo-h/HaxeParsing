package lite.core;

import haxe.Exception;

class PosException extends Exception {
	public override function new(msg:String, pos:PosInfo) {
		var _ = (a:UInt, b:UInt) -> a == b ? Std.string(a) : Std.string(a) + '-' + Std.string(b);
		msg += '(at line ${_(pos.start.line, pos.end.line)}, column ${_(pos.start.column, pos.end.column)})';
		super(msg);
	}
}
