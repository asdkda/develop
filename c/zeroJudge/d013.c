#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void Fibonacci(int index)
{
	int i;
	double sum, pre1 = 1, pre2 = 1, tmp;

	for ( i = 3 ; i < index ; i++ )
	{
		tmp = pre1;
		pre1 += pre2;
		pre2 = tmp;
	}
	sum = pre1 + pre2;
	printf("%.0f\n", sum);
}

int main()
{
	int index;

	while ( scanf("%d", &index) != EOF )
    {
		if ( index > 47 || index < 1 )
			continue;

		else if ( index < 3 )
			printf("1\n");
		else
			Fibonacci(index);
    }
	return 0;
}
