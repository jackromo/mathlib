#include <stdio.h>
#define FNCT 1
#define USER_FNCT 2
#define VARI 0

// Define all functions and types for symbol table.

struct symobj // Type for symbol in table
{
	char *name;
	int type;  // variable or function (user-defined or predefined function)
	union{
		double var;
		double (*fnptr)(); 	// For predefined functions, optimized by C code.
		char *fnval;		// For user-defined functions. Contains a string of the function, which then is evaluated by parser.
	} value;

	char *arg;		// name of argument for user-defined functions

	struct symobj *next;	// pointer to next symbol in list
};

typedef struct symobj symobj;

extern symobj *symtab;

symobj *putsym(char *sym_name, int sym_type);  // Puts a symbol in table
symobj *getsym(char *sym_name);  // Returns a pointer to a specified symbol 
