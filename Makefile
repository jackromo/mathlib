mathlib: mathlib.y mathlib.l
	bison -d mathlib.y
	flex mathlib.l
	gcc -g -o mathlib mathlib.tab.c mathlib.tab.h lex.yy.c symtable.c -lm
