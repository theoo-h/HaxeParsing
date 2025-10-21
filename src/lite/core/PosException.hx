package lite.core;

import haxe.Exception;

// this is pretty bad for multi-lining errors
// FIXME
class PosException extends Exception {
	public override function new(msg:String, pos:PosInfo) {
		msg += ' (at line ${pos.minLine}';
		if (pos.minLine != pos.maxLine) {
			msg += '-${pos.maxLine}';
		}

		msg += ', column ${pos.minColumn}';

		if (pos.minColumn != pos.maxColumn) {
			msg += '-${pos.maxColumn}';
		}

		msg += ')';
		super(msg);
	}
}
