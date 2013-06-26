%{
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define YYSTYPE double
%}

%token NUM

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
	| Expression END { printf("result: %f\n", $1); }
;

Expression:
	NUM { $$ = $1; }
	| Expression PLUS Expression { $$ = $1 + $3; }
	| Expression MULT Expression { $$ = $1 * $3; }
	| Expression MIN Expression { $$ = $1 - $3; }
	| Expression DIV Expression { $$ = $1 / $3; }
	| MIN Expression %prec NEG { $$ = -$2; }
	| Expression POWER Expression { $$ = pow($1, $3); }
	| Expression MOD Expression { $$ = (int)$1 % (int)$3; }
	| LPAREN Expression RPAREN { $$ = $2; }
;

%%

int yyerror(char *s) {
  printf("%s\n", s);
}

int main() {
  if (yyparse())
     fprintf(stderr, "Successful parsing.\n");
  else
     fprintf(stderr, "error found.\n");
}
