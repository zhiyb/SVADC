#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char *argv[])
{
	if (argc != 3)
		return 1;
	unsigned long n = atoi(argv[1]);
	unsigned long max = pow(2, atoi(argv[2]));
	if (n == 0 || max <= 1)
		return 1;
	printf("WIDTH=%lu;\n", n);
	printf("DEPTH=%lu;\n\n", max);
	puts("ADDRESS_RADIX=DEC;");
	puts("DATA_RADIX=DEC;\n");
	puts("CONTENT BEGIN");
	unsigned long i;
	for (i = 0; i != max; i++) {
		unsigned long v = round((sin(M_PI * 2.f * (double)i / (double)max) + 1.f) / 2.f * (double)(pow(2, n) - 1));
		printf("\t%lu : %lu;\n", i, v);
	}
	puts("END;");
}
