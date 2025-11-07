package lite.core;

@:structInit
class PosInfo {
	public var file:String;

	public var start:LitePosition;
	public var end:LitePosition;

	public function new() {}

	public function toStrng():String {
		return 'Position(start: $start, end: $start)';
	}
}

private typedef LitePosition = {
	line:UInt,
	column:UInt
}
