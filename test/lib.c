#include <stdio.h>
int main() {
    double aaa, baab, product;
    printf("Enter two numbers: ");
    scanf("%lf %lf", &aaa, &baab);  
 
    // Calculating product
    product = aaa * baab;

    // %.2lf displays number up to 2 decimal point
    printf("Product = %.2lf", product);
    
    return 0;
}
