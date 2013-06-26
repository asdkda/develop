#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void reverse(char *data)
{
	int i, len = strlen(data);
	char buf;

	for ( i = 0 ; i < len/2 ; i++ )
	{
		buf = data[i];
		data[i] = data[len-i-1];
		data[len-i-1] = buf;
	}
}

int main()
{
	char buf[100];

	while ( scanf("%[^\n]", buf) != EOF )
    {
		getchar();
		reverse(buf);
		printf("%s\n", buf);
    }
	return 0;
}
