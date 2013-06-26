#include <stdio.h> 
#include <stdlib.h> 

int main(void) { 
    double n;

    printf("請輸入整數："); 
    scanf("%ld", &n);
    printf("%ld = ", n);
/*
    int i;
    for(i = 2; i * i <= n;) { 
        if(n % i == 0) { 
            printf("%d * ", i); 
            n /= i; 
        } 
        else 
            i++; 
    } 

    printf("%f\n", n); 
*/
    return 0; 
} 
