package lite;

import lite.core.PosInfo;

enum Token {
	TKeyword(t:Keyword, pos:PosInfo);
	TIdent(name:String, pos:PosInfo);

	TLiteral(t:Literal, pos:PosInfo);

	TOperator(t:Operator, pos:PosInfo);
	TSymbol(t:Symbol, pos:PosInfo);

	TEof;
}

enum Symbol {
	Comma;

	Semicolon;
	Colon;

	// ()
	LParen;
	RParen;

	// []
	LBracket;
	RBracket;

	// {}
	LBrace;
	RBrace;
}

enum Literal {
	INT(value:Int);
	FLOAT(value:Float);
	STRING(value:String);
	BOOL(value:Bool);
	NULL;
}

enum Operator {
	// !
	Not;

	// !=
	NotEqual;

	// ||
	Or;

	// &&
	And;

	// <>
	LessThan;
	GreaterThan;

	// <= =>
	LessEqualThan;
	GreaterEqualThan;

	// <- ->
	LArrow;
	RArrow;

	// =
	Assign;

	// ==
	Equal;

	// "*"
	Mult;
	// "*="
	MultAssign;

	// "+"
	Add;
	// "+="
	AddAssign;
	// "++"
	AddIncrement;

	// "-"
	Sub;
	// "-="
	SubAssign;
	// "--"
	SubDecrement;

	// "/"
	Div;
	// "/="
	DivAssign;

	Mod;
}

enum Keyword {
	VAR;
	FUNCTION;

	IF;
	ELIF;
	ELSE;

	WHILE;
	FOR;
}
