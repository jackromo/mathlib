%{
#define YYSTYPE double

#include "mathlib.tab.h"
#include <stdio.h>
#include <stdlib.h>
%}

digit [0-9]
integer {digit}+
num {integer}("."{integer})?

%%

[ \t]		;
{num}	{ yylval = atof(yytext);
	return NUM;
	}
"+"		{ return PLUS; }
"-"		{ return MIN; }
"*"		{ return MULT; }
"/"		{ return DIV; }
"("		{ return LPAREN; }
")"		{ return RPAREN; }
"^"		{ return POWER; }
"\n"		{ return END; }

%%
yywrap() { return 1; }
