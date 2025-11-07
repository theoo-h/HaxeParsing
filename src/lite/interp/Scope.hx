package lite.interp;

import haxe.ds.StringMap;

@:nullSafety(Strict)
class Scope {
	private var _:StringMap<Null<LiteValue>>;
	private var parent:Null<Scope>;

	public function new(parent:Null<Scope> = null) {
		this.parent = parent;

		_ = new StringMap<LiteValue>();
	}

	public function set(id:String, value:Null<LiteValue>):Null<LiteValue> {
		_.set(id, value);
		return value;
	}

	public function assign(ident:String, val:LiteValue):LiteValue {
		if (_.exists(ident)) {
			_.set(ident, val);
			return val;
		}
		return parent != null ? parent.assign(ident, val) : VNull;
	}

	public function get(id:String):Null<LiteValue> {
		return _.get(id) ?? parent?.get(id) ?? null;
	}
}
