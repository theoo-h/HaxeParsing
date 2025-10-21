package lite;

import lite.Token;

@:structInit
class Expr {
	public var expr:ExprType;

	public function toString() {
		return 'Expr[expr: $expr]';
	}
}

enum ExprType {
	EBinOp(left:Expr, right:Expr, op:Operator);
	EUnaryOp(left:Expr, op:Operator);
	ELiteral(literal:Literal);
	EIdent(ident:String);
	EEof;
}
