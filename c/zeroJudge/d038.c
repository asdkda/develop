#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void multiplied(char *mulitplicand, char *multiplier, int size1, int size2)
{
	int i, j, carry = 0, product;
	char final[5001];

	memset(final, 0, sizeof(final));
	for (i = size1-1 ; i > -1 ; i--)
	{
		if (mulitplicand[i] == 0)
		{
			break;
		}
		for ( j = size2-1 ; j > -1 ; j--)
		{
			if (multiplier[j] == 0)
			{
				break;
			}
			product = (mulitplicand[i]-'0') * (multiplier[j]-'0');
			carry = product / 10;
			final[i+j-4] += product % 10;
			if (carry)
			{
				final[i+j-5] += carry;
			}
		}
	}

	carry = 0;
	for (i = 4999 ; i >= 0 ; i--)
	{
		final[i] += carry;
		if(final[i] > 9)
		{
			carry = final[i]/10;
			final[i] = final[i]%10;
		}
		else
			carry = 0;

		mulitplicand[i] = final[i] + '0';
	}
}

void add1(char *target)
{
	int carry = 0;
	*target += 1;

	if (*target > '9')
	{
		carry = 1;
		*target = '0';
	}
	while(carry == 1)
	{
		target--;
		if(*target == 0)
			*target = '1';
		else
			*target += 1;
		carry = 0;
		if (*target > '9')
		{
			carry = 1;
			*target = '0';
		}
	}
}

int main()
{
	int a1, i;
	char mulitplicand[5001], multiplier[5];

	do
	{
		if (scanf("%d", &a1) == EOF)
			return 0;

		if (a1 > 1000 || a1 < 1)
			break;

		memset(mulitplicand, 0, sizeof(mulitplicand));
		memset(multiplier, 0, sizeof(multiplier));

		multiplier[4] = '2';
		mulitplicand[4999] = '1';
		for ( i = 2 ; i <= a1 ; i++ )
		{
			multiplied(mulitplicand, multiplier, 5000, 5);
			add1(&multiplier[4]);
		}

		for ( i = 0 ; i < sizeof(mulitplicand) ; i++ )
			if (mulitplicand[i] != 0 && mulitplicand[i] != '0')
				break;
		printf("%s\n", mulitplicand+i);
	}while(1);
	return 0;
}
