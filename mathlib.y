%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "symtable.h"

double ans;  //Answer to previous operation is remembered in this variable. Represented by ANS token.
%}

%union {
	double val;            // For returning numbers
	struct symobj *tptr;   // For returning symbol-table pointers
}

%token <val> NUM ANS

%token <tptr> VAR FUNC  // Variables and functions

%type <val> Expression

%right ASSIGN

%left MULT DIV MOD
%left PLUS MIN

%left NEG
%right POWER

%token LPAREN RPAREN

%token END

%start Input

%%

Input:

	| Input Line
;

Line:
	END
	| Expression END { ans = $1;
			printf("result: %f\n", $1); }
;

Expression:
	NUM { $$ = $1; }
	| ANS { $$ = ans; }
	| VAR { $$ = $1->value.var; }
	| VAR ASSIGN Expression { $$ = $3; $1->value.var = $3; }
	| Expression PLUS Expression { $$ = $1 + $3; }
	| Expression MULT Expression { $$ = $1 * $3; }
	| Expression MIN Expression { $$ = $1 - $3; }
	| Expression DIV Expression { $$ = $1 / $3; }
	| MIN Expression %prec NEG { $$ = -$2; }
	| Expression POWER Expression { $$ = pow($1, $3); }
	| Expression MOD Expression { $$ = (int)$1 % (int)$3; }
	| LPAREN Expression RPAREN { $$ = $2; }
	| FUNC LPAREN Expression RPAREN { $$ = (*($1->value.fnptr))($3); }
;

%%

struct init  // Prewritten function type to be put into symbol table at beginning (sin, cos, etc.)
{
  char *fname;
  double (*fnct)();
};

struct init fnc_list[]  // List of functions to initially put into symbol table
  = {
      "sin", sin,
      "cos", cos,
      "atan", atan,
      "ln", log,
      "exp", exp,
      "sqrt", sqrt,
      0, 0
    };

int init_list()  // Initializes symbol table with fnc_list
{

	int i;
	symobj *ptr;
	for (i = 0; fnc_list[i].fname != 0; i++)
	{
		ptr = putsym (fnc_list[i].fname, FNCT);
		ptr->value.fnptr = fnc_list[i].fnct;
	}
	return 0;

}

int yyerror(char *s)
{
	printf("%s\n", s);
}

symobj *symtab = (symobj *)0;

int main()
{
	init_list();

	if (yyparse())
		fprintf(stderr, "Successful parsing.\n");
	else
		fprintf(stderr, "error found.\n");
}
