#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char *argv[])
{
	if (argc != 3)
		return 1;
	unsigned long frac = atoi(argv[1]), n = atoi(argv[2]);
	if (n == 0)
		return 1;
	unsigned long width = frac + 2;

	printf("WIDTH=%lu;\n", width * 2);
	printf("DEPTH=%lu;\n\n", n);
	puts("ADDRESS_RADIX=DEC;");
	puts("DATA_RADIX=DEC;\n");
	puts("CONTENT BEGIN");
	unsigned long i;
	for (i = 0; i != n; i++) {
		double w = -M_PI * (double)i / (double)n;
		unsigned long re = round(cos(w) * pow(2.0, frac));
		unsigned long im = round(sin(w) * pow(2.0, frac));
		re = re & ((1ul << width) - 1);
		im = im & ((1ul << width) - 1);
		unsigned long v = (im << width) | re;
		printf("\t%lu : %lu;\n", i, v);
	}
	puts("END;");
}
