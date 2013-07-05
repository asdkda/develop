#include <stdio.h>

#include "interface.h"

int main (int argc, char **argv)
{
	interface *entry;

	entry = new_interface("test");
	interface_print(entry);
//	printf("line=%s\n", entry->line);
	fini_interface(entry);

	return 0;  // make sure your main returns int
}
