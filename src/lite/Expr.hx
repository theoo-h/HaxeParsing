package lite;

import lite.Token;

@:structInit
class Expr {
	public var expr:ExprType;

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

	EIfStat(cond:Expr, body:Expr);

	ERange(min:Expr, max:Expr);
	EAssign(ident:VIdent, value:Expr);
	EBinOp(left:Expr, right:Expr, op:Operator);
	EUnaryOp(left:Expr, op:Operator);
	ELiteral(literal:Literal);
	EIdent(ident:VIdent);
	EEof;
}

typedef FArgument = {
	name:String
}

typedef VIdent = String;
