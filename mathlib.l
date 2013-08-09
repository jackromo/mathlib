%{
#include "mathlib.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include "symtable.h"
#define STR_LEN 20		// Length of function string, not including \0 ending.

symobj *last_func;	// Pointer to a recently made or used user-defined function, used in former case to transfer pointer to 'mathlib.l'.
double last_arg = 0;	// Value of a user_defined function's argument, used to send this value to argument function.

extern double ans;
extern int yyparse();
extern int parsing_lvl;
%}

digit		[0-9]
integer		{digit}+
exponent	[eE][+-]?{integer}
num		{integer}("."{integer})?{exponent}?
string		[a-z]+
%%

[ \t]		;
{num}		{ yylval.val = atof(yytext);
		  return NUM; }
"+"		{ return PLUS; }
"-"		{ return MIN; }
"*"		{ return MULT; }
"/"		{ return DIV; }
"("		{ return LPAREN; }
")"		{ return RPAREN; }
"^"		{ return POWER; }
"%"		{ return MOD; }
":"		{ return F_ASSIGN; }
"="		{ return ASSIGN; }
"<"		{ return LT; }
">"		{ return GT; }
"<="		{ return LE; }
">="		{ return GE; }
"=="		{ return ET; }
"if"		{ return IF; }
"then"		{ return THEN; }
"else"		{ return ELSE; }
"ans"		{ return ANS; }
{string}	{ symobj *s = getsym(yytext);
		  if(s == 0)
		  	s = putsym(yytext, VAR);
		  yylval.tptr = s;
		  if(s->type == FNCT || s->type == USER_FNCT)
			return FUNC;
		  else if(parsing_lvl > 0 && strcmp(yytext, last_func->arg) == 0) {
			 yylval.val = last_arg;
			 return NUM;
		  }
		  return VAR; }
"\n"		{ return END; }

%%

symobj *make_fnc(symobj *s, char *arg)
{
		char p, *t; 

		s->type = USER_FNCT;

		s->arg = malloc(strlen(arg) + 1);
		if(s->arg == NULL)
			exit(EXIT_FAILURE);

		strcpy(s->arg, arg);

		s->value.fnval = malloc(STR_LEN + 2);
		t = s->value.fnval;

		while((p = input()) != '\n')
			*t++ = p;

		*t++ = '\n';
		*t = '\0';

		unput(p);
		return s;
}

double parse_fnc (symobj *sym, double param, double arg)
{
	double prev_ans = ans;
	double result;
	char c;

	last_arg = param;
	last_func = sym;
	
	char *str = malloc(strlen(sym->value.fnval) + 2);
	if(str == NULL)
		exit(EXIT_FAILURE);
	
	strcpy(str, sym->value.fnval);

	yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));

	YY_BUFFER_STATE my_string_buffer = yy_scan_string(str);
 
	yy_switch_to_buffer(my_string_buffer);

	parsing_lvl += 1;
	yyparse();

	parsing_lvl -= 1;
	result = ans;
	ans = prev_ans;
	yy_flush_buffer(my_string_buffer);
	yypop_buffer_state();
	return result;
}

yywrap() { return 1; }
