#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void add(char *a1, char *a2, char *result)
{
	int i, carry=0, len1 = strlen(a1), len2 = strlen(a2);
	int finalLen = (len1 >= len2) ? len1 : len2;
	char sum;

	for ( i = 0 ; i < finalLen ; i++ )
	{
		if ( i+1 > len1 )
			sum = a2[len2-i-1]+carry;
		else if ( i+1 > len2 )
			sum = a1[len1-i-1]+carry;
		else
			sum = (a1[len1-i-1]-'0') + (a2[len2-i-1]-'0') + carry + '0';

		carry = 0;
		if (sum > '9')
		{
			carry++;
			sum = sum - 10;
		}
		result[finalLen-i] = sum ;
	}
	if (carry)
		result[0] = '1';
}

int main()
{
	char buf1[101], buf2[101], sum[200] = {0};
	int i;

	do
	{
		memset(sum, 0, sizeof(sum));
		if (scanf("%s", buf1) == EOF)
			return 0;
		if (scanf("%s", buf2) == EOF)
			return 0;

		add(buf1, buf2, sum);
		for ( i = 0 ; i < sizeof(sum) ; i++ )
		{
			if (sum[i] == 0 || (sum[i] == '0' && sum[i+1] != 0))
				continue;
			else
				break;
		}
		printf("%s\n", sum+i);
	}while(1);
	return 0;
}
