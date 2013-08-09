%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "symtable.h"

extern symobj *make_fnc(symobj *s, char ending, int unput_end_char, int arg_count, char *args[]);// Used to create a user-defined function.	
extern double parse_fnc(symobj *sym, int param_count, double args[]);				// Used to parse a function's string.

extern double if_stmt(double param);		// Carries out an if-statement (was too big to not put in a function)

int parsing_lvl = 0;		// Level of parsing (0 if main input, 1 if a function, 2 if a function in a function, etc.)
double ans;			// Answer to previous operation is remembered in this variable. Represented by ANS token.
int arg_count = 0;		// Number of arguments in most recently defined or used function.
%}

%union {
	double val;		// For returning numbers
	struct symobj *tptr;	// For returning symbol-table pointers
	double val_array[8];	// For returning arrays of numbers
	char *str_array[8];	// For returning arrays of strings
}

%token <val> NUM ANS

%token <tptr> VAR FUNC  // Variables and functions

%type <val> Expression Assignment Operation If_stmt Conditionnal
%type <val_array> Func_args 
%type <str_array> Func_assign

%right ASSIGN F_ASSIGN

%left MULT DIV MOD
%left PLUS MIN

%left NEG
%right POWER

%token LPAREN RPAREN C_LPAREN C_RPAREN //normal brackets () and curly brackets {} 

%token END

%left COMMA

%right IF THEN ELSE
%left GT LT GE LE ET NE AND OR // >, <, >=, <=, ==, !=, &&, ||

%start Input

%%

Input:

	| Input Line
;

Line:
	END
	| Expression END { ans = $1;
			 if(parsing_lvl == 0)
				printf("result: %lf\n", $1); }
;

Expression:
	NUM { $$ = $1; }
	| ANS { $$ = ans; }
	| VAR { $$ = $1->value.var; }
	| Assignment { $$ = $1; }
	| Operation { $$ = $1; }
	| If_stmt { $$ = $1; }
	| Conditionnal { $$ = $1; }
	| MIN Expression %prec NEG { $$ = -$2; }
	| LPAREN Expression RPAREN { $$ = $2; }
	| FUNC LPAREN Func_args RPAREN { if($1->type == FNCT)		$$ = (*($1->value.fnptr))($3[0]);
					else if($1->type == USER_FNCT)	$$ = parse_fnc($1, arg_count, $3);  /*Parse the string 'fnval'.*/ }
;

Assignment:
	VAR ASSIGN Expression { $$ = $3;
				$1->value.var = $3; }
	| VAR LPAREN Func_assign RPAREN F_ASSIGN { $$ = 0;
					   $1 = make_fnc($1, '\n', 1, arg_count, $3); }
;

Operation:
	Expression PLUS Expression { $$ = $1 + $3; }
	| Expression MULT Expression { $$ = $1 * $3; }
	| Expression MIN Expression { $$ = $1 - $3; }
	| Expression DIV Expression { $$ = $1 / $3; }
	| Expression POWER Expression { $$ = pow($1, $3); }
	| Expression MOD Expression { $$ = (int)$1 % (int)$3; }
;

If_stmt:
	IF Expression THEN C_LPAREN { $$ = if_stmt($2); }
;

Conditionnal:
	Expression GT Expression { $$ = ($1 > $3 ? 1:0); }
	| Expression LT Expression { $$ = ($1 < $3 ? 1:0); }
	| Expression GE Expression { $$ = ($1 >= $3 ? 1:0); }
	| Expression LE Expression { $$ = ($1 <= $3 ? 1:0); }
	| Expression ET Expression { $$ = ($1 == $3 ? 1:0); }
	| Expression NE Expression { $$ = ($1 != $3 ? 1:0); }
	| Expression AND Expression { $$ = ($1 && $3 ? 1:0); }
	| Expression OR Expression { $$ = ($1 || $3 ? 1:0); }
;

Func_assign:
	VAR { arg_count = 0; $$[0] = $1->name; arg_count++; }
	| Func_assign COMMA VAR { $$[arg_count] = $3->name; arg_count++; }
;

Func_args:
	Expression { arg_count = 0; $$[0] = $1; arg_count++; }
	| Func_args COMMA Expression { $$[arg_count] = $3; arg_count++; }
;

%%

struct f_init  // Prewritten function type to be put into symbol table at beginning (sin, cos, etc.)
{
	char *fname;
	double (*fnct)();
};

struct v_init  // Prewritten variables to be put into symbol table at beginning (pi, e, etc.)
{
	char *vname;
	double num;
};

struct f_init fnc_list[]  // List of functions to initially put into symbol table
	= {
		"sin", sin,
		"cos", cos,
		"tan", tan,
		"atan", atan,
		"sinh", sinh,
		"ln", log,
		"exp", exp,
		"sqrt", sqrt,
		0, 0
	};

struct v_init var_list[]  // List of variables to initially put into symbol table
	= {
		"pi", 3.14593654,
		"e", 2.718281828,
		0, 0
	};

int init_list()  // Initializes symbol table with fnc_list and var_list
{

	int i;
	symobj *ptr;

	for (i = 0; fnc_list[i].fname != 0; i++)
	{
		ptr = putsym (fnc_list[i].fname, FNCT);
		ptr->value.fnptr = fnc_list[i].fnct;
	}
	for (i = 0; var_list[i].vname != 0; i++)
	{
		ptr = putsym (var_list[i].vname, VARI);
		ptr->value.var = var_list[i].num;
	}
	return 0;

}

int yyerror(char *s)
{
	printf("Error found: %s\n", s);
}

symobj *symtab = (symobj *)0;

int main()
{
	init_list();

	if (!yyparse())
		fprintf(stderr, "Successful parsing.\n");
	else
		fprintf(stderr, "Aborted parsing due to error.\n");
}
