%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"

extern symobj *make_fnc(symobj *s, char *arg);		// Used to create a user-defined function.	
extern double parse_fnc(struct symobj *, double);	// Used to parse a function's string.

int parsing_lvl = 0;		// Level of parsing (0 if main input, 1 if a function, 2 if a function in a function, etc.)
double ans;			// Answer to previous operation is remembered in this variable. Represented by ANS token.
%}

%union {
	double val;            // For returning numbers
	struct symobj *tptr;   // For returning symbol-table pointers
}

%token <val> NUM ANS

%token <tptr> VAR FUNC  // Variables and functions

%type <val> Expression Assignment Operation If_stmt Conditionnal

%right ASSIGN F_ASSIGN

%left MULT DIV MOD
%left PLUS MIN

%left NEG
%right POWER

%token LPAREN RPAREN

%token END

%right IF THEN ELSE
%left GT LT GE LE ET

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
	| FUNC LPAREN Expression RPAREN { if($1->type == FNCT)		$$ = (*($1->value.fnptr))($3);
					else if($1->type == USER_FNCT)	$$ = parse_fnc($1, $3);  /*Parse the string 'fnval' in function.*/ }
;

Assignment:
	VAR ASSIGN Expression { $$ = $3;
				$1->value.var = $3; }
	| VAR LPAREN VAR RPAREN F_ASSIGN { $$ = 0;
					   $1 = make_fnc($1, $3->name); }
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
	IF Expression THEN Expression ELSE Expression { if($2)	$$ = $4;
							else	$$ = $6; }
;

Conditionnal:
	Expression GT Expression { $$ = ($1 > $3 ? 1:0); }
	| Expression LT Expression { $$ = ($1 < $3 ? 1:0); }
	| Expression GE Expression { $$ = ($1 >= $3 ? 1:0); }
	| Expression LE Expression { $$ = ($1 <= $3 ? 1:0); }
	| Expression ET Expression { $$ = ($1 == $3 ? 1:0); }
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
