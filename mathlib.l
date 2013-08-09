%{
#include "mathlib.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include "symtable.h"
#define STR_LEN 200		// Length of function string, not including \0 ending.

symobj *last_func;		// Stack of pointers to recently made or used user-defined functions.
double last_arg = 0;	// Stack of values of user_defined functions' argument, used to send this value to argument function.

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
"{"		{ return C_LPAREN; }
"}"		{ return C_RPAREN; }
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
"\n"		{  return END; }

%%

int skip_until(char ending, int unput_char)
{
	char c;
	while((c = input()) != ending)
		;
	if(unput_char == 1)
		unput(c);
	return 0;
}

symobj *make_fnc(symobj *s, char *arg, char ending, int unput_end_char)
{
		char p, *t;

		s->type = USER_FNCT;

		s->arg = malloc(strlen(arg) + 1);
		if(s->arg == NULL)
			exit(EXIT_FAILURE);

		strcpy(s->arg, arg);

		s->value.fnval = malloc(STR_LEN + 2);
		if(s->value.fnval == NULL)
			exit(EXIT_FAILURE);

		t = s->value.fnval;

		while((p = input()) != ending)
			*t++ = p;

		*t++ = '\n';
		*t = '\0';
		if(unput_end_char == 1)
			unput(p);
		return s;
}

double parse_fnc (symobj *sym, double param)
{
	double prev_ans = ans;
	double result;
	char c;

	last_func = sym;
	last_arg = param;
	
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

double parse_expr(char ending, int unput_ending)
{
	symobj *temp;
	double result;

	if((temp = getsym("temp")) == 0)
		temp = putsym("temp", USER_FNCT);

	if(parsing_lvl == 0) {
		if(ending == '\n' || unput_ending == 1)
			temp = make_fnc(temp, "0", ending, 1);
		else
			temp = make_fnc(temp, "0", ending, 0);
		result = parse_fnc(temp, 0);
	}
	else {
		if(ending == '\n' || unput_ending == 1)
			temp = make_fnc(temp, last_func->arg, ending, 1);
		else
			temp = make_fnc(temp, last_func->arg, ending, 0);
		result = parse_fnc(temp, last_arg);

	}


	return result;
}

double if_stmt(double param)
{
	double result = 0;
	if(param)
	{
		result = parse_expr('}', 0);
		if(yylex() == ELSE)
			skip_until('}', 0);
		else
			yyless(0);
	}
	else
	{
		skip_until('}', 0);
		if(yylex() == ELSE)
		{
			if(yylex() == C_LPAREN)
				result = parse_expr('}', 0);
		}
		else
			yyless(0);
	}
	return result;
}


yywrap() { return 1; }
