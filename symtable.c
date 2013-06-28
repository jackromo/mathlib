#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"

symobj *putsym (char *sym_name, int sym_type)
{

	symobj *ptr;
 	ptr = (symobj *) malloc(sizeof(symobj));
	if(ptr == NULL)
		exit(EXIT_FAILURE);

	ptr->name = (char *) malloc(strlen(sym_name) + 1);
	strcpy (ptr->name,sym_name);
	ptr->type = sym_type;
	ptr->value.var = 0; // set value to 0 even if function
	ptr->next = (symobj *)symtab;
	symtab = ptr;
	return ptr;

}

symobj *getsym (char *sym_name)
{

	symobj *ptr;
	for (ptr = symtab; ptr != (symobj *) 0; ptr = (symobj *)ptr->next)
	{
		if (strcmp (ptr->name,sym_name) == 0)
			return ptr;
	}
	return 0;

}
