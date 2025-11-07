package lite;

import lite.Token;
import lite.core.PosInfo;

@:structInit
class Expr {
	public var expr:ExprType;
	public var pos:PosInfo;

	public function toString() {
		return {
			expr: expr
		};
	}
}

enum ExprType {
	EBlock(exprs:Array<Expr>);

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
	EBinOp(left:Expr, right:Expr, op:Operator);
	EUnaryOp(left:Expr, op:Operator);
	ELiteral(literal:Literal);
	EIdent(ident:VIdent);
	EEof;
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
