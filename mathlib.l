%{
#include "mathlib.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "symtable.h"
#define STR_LEN 200		// Length of function string, not including \0 ending.

symobj *last_func;		// Pointer to recently made or used user-defined function.
double last_arg[MAX_ARGS];	// Values of user_defined function's arguments, used to send this value to argument function.

extern double ans;
extern int yyparse();
extern int parsing_lvl;
extern int arg_count;		// Number of arguments in function.
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
"!="		{ return NE; }
"&&"		{ return AND; }
"||"		{ return OR; }
","		{ return COMMA; }
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
		  else if(parsing_lvl > 0) {
			int i;
			for(i = 0; i < arg_count; i++) {
				if(strcmp(yytext, last_func->arg[i]) == 0) {
					yylval.val = last_arg[i];
			 		return NUM;
				}
			}
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

symobj *make_fnc(symobj *s, char ending, int unput_end_char, int arg_count, char *args[])
{
	int i;
	char p, *t, *current_str;

	current_str = malloc(STR_LEN + 1);

	s->type = USER_FNCT;

	for( i = 0; i < arg_count && i < MAX_ARGS; i++)
	{
		strcpy(current_str, args[i]);

		s->arg[i] = malloc(strlen(current_str) + 1);
		if(s->arg[i] == NULL)
			exit(EXIT_FAILURE);
		
		strcpy(s->arg[i], current_str);
	}

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

double parse_fnc (symobj *sym, int param_count, double args[])
{
	int count;

	double prev_ans = ans;
	double result;
	char c;

	last_func = sym;

	for( count = 0; count < param_count; count++)
		last_arg[count] = args[count];

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
	char *temp_arg[] = {"0"};
	double temp_param[] = {0};

	if((temp = getsym("temp")) == 0)
		temp = putsym("temp", USER_FNCT);

	if(parsing_lvl == 0)
	{
		if(ending == '\n' || unput_ending == 1)
			temp = make_fnc(temp, ending, 1, 1, temp_arg);
		else
			temp = make_fnc(temp, ending, 0, 1, temp_arg);
		result = parse_fnc(temp, 1, temp_param);
	}
	else
	{
		if(ending == '\n' || unput_ending == 1)
			temp = make_fnc(temp, ending, 1, arg_count, last_func->arg);
		else
			temp = make_fnc(temp, ending, 0, arg_count, last_func->arg);
		result = parse_fnc(temp, arg_count, last_arg);
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
