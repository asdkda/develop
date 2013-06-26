#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main()
{
	int a1, a2, i, j, repeater;
	char *result, quotient;
	char *dividend;

	do
	{
		if (scanf("%d", &a1) == EOF)
			return 0;
		if (scanf("%d", &a2) == EOF)
			return 0;

		if (a2 > 300000 || a2 < 1)
			break;

		repeater = 0;
		a1 %= a2;
		dividend = malloc(a2);
		memset(dividend, 0, a2);
		result = malloc(a2+1);
		memset(result, 0, a2+1);

		dividend[a1] = 1;
		for ( i = 0 ; i < a2 ; i++ )
		{
			quotient = 10 * a1 / a2 + '0';
			a1 = 10 * a1 % a2;
			if ( a1 == 0 )
				break;
			else if ( dividend[a1] == 0 )
			{
				dividend[a1] = 1;
			}
			else
			{
				memset(dividend, 0, a2);
				dividend[a1] = 1;
				for ( j = 0 ; j < a2 ; j++ )
				{
					quotient = 10 * a1 / a2 + '0';
					a1 = 10 * a1 % a2;
					result[j] = quotient;
					if ( dividend[a1] == 0 )
					{
						dividend[a1] = 1;
					}
					else
						break;
				}
				repeater = 1;
				break;
			}
		}

		if ( repeater )
			printf("%s\n", result);
		else
			printf("not repeater\n");

		free(result);
		free(dividend);
	}while(1);
	return 0;
}
