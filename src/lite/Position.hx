package lite;

@:structInit
class Position {
	public var minLine:UInt;
	public var maxLine:UInt;

	public var minColumn:UInt;
	public var maxColumn:UInt;

	public function new() {}

	public function toString():String {
		return 'Position[minLine: $minLine, minColumn: $minColumn, maxLine: $maxLine, maxColumn: $maxColumn]';
	}
}
