#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main()
{
	int a1, i, index, getNumber = 0, first = 1, sum = 0;
	char buf[10000], number[100];

	memset(buf, 0, sizeof(buf));
	while ( scanf("%[^\n]", buf) != EOF )
	{
		getchar();
		for ( i = 0 ; i < sizeof(buf) ; i++ )
		{
			if ( getNumber == 0 && buf[i] >= '0' && buf[i] <= '9' )
			{
				getNumber = 1;
				index = 1;
				number[0] = buf[i];
			}
			else if ( buf[i] >= '0' && buf[i] <= '9' )
			{
				number[index] = buf[i];
				index++;
			}
			else if ( getNumber )
			{
				number[index] = '\0';
				a1 = atoi(number);
				if (first == 1)
				{
					printf("%d", a1);
					first = 0;
				}
				else
					printf("+%d", a1);
				getNumber = 0;
				sum += a1;
			}

			if ( buf[i] == '\0' )
				break;
		}
		printf("=%d\n", sum);
		sum = 0;
		first = 1;
		memset(buf, 0, sizeof(buf));
	}

	return 0;
}
