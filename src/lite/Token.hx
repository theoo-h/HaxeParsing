package lite;

import lite.Position;

enum Token {
	TKeyword(t:Keyword, pos:Position);
	TIdent(name:String, pos:Position);

	TLiteral(t:Literal, pos:Position);

	TOperator(t:Operator, pos:Position);
	TSymbol(t:Symbol, pos:Position);
}

enum Symbol {
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
	// =
	ASSIGN;

	// ==
	EQUAL;

	// "*"
	MULT;
	// "*="
	MULT_ASSIGN;

	// "+"
	ADD;
	// "+="
	ADD_ASSIGN;
	// "++"
	ADD_INCREMENT;

	// "-"
	SUB;
	// "-="
	SUB_ASSIGN;
	// "--"
	SUB_DECREMENT;

	// "/"
	DIV;
	// "/="
	DIV_ASSIGN;
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
