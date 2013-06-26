#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int isPalindrome(char *data)
{
	int i, len = strlen(data);

	for ( i = 0 ; i < len/2 ; i++ )
	{
		if (data[i] != data[len-i-1])
			return -1;
	}

	return 0;
}

int main()
{
	char buf[100];
	int ret;

	while ( scanf("%s", buf) != EOF )
    {
		ret = isPalindrome(buf);
		if (ret == -1)
			printf("No\n");
		else
			printf("Yes\n");
    }
	return 0;
}
