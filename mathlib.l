%{
#include "mathlib.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include "symtable.h"
%}

digit		[0-9]
integer		{digit}+
exponent	[eE][+-]?{integer}
num		{integer}("."{integer})?{exponent}?
string		[a-z]+
%%

[ \t]		;
{num}	{ yylval.val = atof(yytext);
	return NUM;
	}
"+"		{ return PLUS; }
"-"		{ return MIN; }
"*"		{ return MULT; }
"/"		{ return DIV; }
"("		{ return LPAREN; }
")"		{ return RPAREN; }
"^"		{ return POWER; }
"%"		{ return MOD; }
"="		{ return ASSIGN; }
"ans"		{ return ANS; }
{string}	{ symobj *s = getsym(yytext);
		  if(s == 0)
		  	s = putsym(yytext, VAR);
		  yylval.tptr = s;
		  if(s->type == FNCT)
			return FUNC;
		  return VAR; }

"\n"		{ return END; }

%%
yywrap() { return 1; }
