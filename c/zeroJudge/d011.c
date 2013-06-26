#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int compare(char *src, char *dst)
{
	int i;

	for ( i = 0 ; ; i++ )
	{
		if (src[i] != dst[i])
			return -1;
		else if (src[i] == '\0')
			return 1;
	}
}

int main()
{
	char buf1[100], buf2[100];
	int ret;

	do
	{
	if (scanf("%s", buf1) == EOF)
		return 0;
	if (scanf("%s", buf2) == EOF)
		return 0;

	ret = compare(buf1, buf2);
	if (ret == 1)
		printf("Yes\n");
	else
		printf("No\n");
	}while(1);
	return 0;
}
