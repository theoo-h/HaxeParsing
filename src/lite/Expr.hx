package lite;

import lite.Token;
import lite.core.PosInfo;

@:structInit
class Expr {
	public var expr:ExprType;
	public var pos:PosInfo;

	public function toString() {
		return '{ expr: $expr, pos: $pos }';
	}
}

enum ExprType {
	// TODO: move this to literals (make custom literal enum for exprs)
	EArray(mem:Array<Expr>);

	EArrayAccess(object:Expr, index:Expr);
	EBlock(exprs:Array<Expr>);

	EStructDecl(struct:StructDef);
	EVarDecl(ident:VIdent, expr:Expr);
	EFuncDecl(name:String, params:Array<FArgument>, body:Expr);

	// for (Intialization, Condition, Incrementation)
	EForCond(init:Expr, cond:Expr, incr:Expr, body:Expr);

	// for (Ident $in Iterable)
	EForIn(ident:VIdent, iterable:Expr, body:Expr);

	// while (Condition);
	EWhile(condition:Expr, body:Expr);

	EIfStat(cond:Expr, then:Expr, fallback:Expr);

	ECall(left:Expr, args:Array<Expr>);

	EField(object:Expr, field:String);

	EEscape(kind:EscapeType);

	ERange(min:Expr, max:Expr);

	EAssign(ident:VIdent, value:Expr);
	EFieldAssign(parent:Expr, ident:String, value:Expr);

	EBinOp(left:Expr, right:Expr, op:Operator);
	EUnaryOp(left:Expr, op:Operator);
	ELiteral(literal:Literal);
	EIdent(ident:VIdent);
	EEof;
}

@:structInit
@:publicFields
class StructDef {
	// the name of the struct
	var name:String;

	// fields of the struct
	var fields:Array<StructField>;

	// the constructor function (can be null)
	var constructor:Null<StructField>;
	// parent (only if the struct is extending from other struct)
	// var parent:Null<StructDef>:
}

@:structInit
@:publicFields
class StructField {
	var expr:Expr;
	var pos:PosInfo;

	public function toString() {
		return '{expr: $expr, pos: $pos }';
	}
}

enum EscapeType {
	Break;
	Continue;
	Return(expr:Expr);
}

typedef FArgument = {
	name:String
}

typedef VIdent = String;
