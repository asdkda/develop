
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "private.h"

void interface_print(const interface *entry)
{
	if (entry && entry->line)
		printf("line=%s\n", entry->line);
}

static void init_interface(interface *entry, const char *text)
{
	if (entry == NULL)
		return;

	entry->line = strdup(text);
}

interface *new_interface(const char *text)
{
	interface *this;

	this = malloc(sizeof(interface));
	if (this)
		init_interface(this, text);

	return this;
}

void fini_interface(interface *entry)
{
	if (entry == NULL)
		return;

	free(entry->line);
	free(entry);
}
