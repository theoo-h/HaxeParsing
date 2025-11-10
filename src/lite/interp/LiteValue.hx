package lite.interp;

import haxe.ds.StringMap;
import lite.Expr;
import lite.interp.Scope;

enum LiteValue {
	VInt(v:Int);
	VFloat(v:Float);
	VBool(v:Bool);
	VString(v:String);
	VArray(v:Array<LiteValue>);
	VNull;
	VVoid;

	VNativeFun(f:(Array<LiteValue>) -> LiteValue);
	VFun(f:RuntimeFun);
	VScope(s:Scope);
}

@:structInit
@:publicFields
class NativeFun {
	var name:String;
	var c:(Array<LiteValue>) -> LiteValue;
}

@:structInit
@:publicFields
class RuntimeFun {
	var name:String;
	var args:Array<LiteValue>;
	var body:Expr;
	var env:Scope;

	public function toString() {
		return 'RuntimeFun(name: $name, args: $args, body: $body, env: $env)';
	}
}
