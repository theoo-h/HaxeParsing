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

	EVarDecl(ident:String, expr:Expr);
	EFuncDecl(name:String, params:Array<FArgument>, expr:Expr);

	EAssign(ident:String, value:Expr);
	EBinOp(left:Expr, right:Expr, op:Operator);
	EUnaryOp(left:Expr, op:Operator);
	ELiteral(literal:Literal);
	EIdent(ident:String);
	EEof;
}

typedef FArgument = {
	name:String
}
