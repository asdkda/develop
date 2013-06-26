#include <stdio.h>
#include <stdlib.h>

int main()
{
	char buf[100];

	while ( scanf("%s", buf) != EOF )
    {
		printf("Hello %s\n", buf);
    }
	return 0;
}

