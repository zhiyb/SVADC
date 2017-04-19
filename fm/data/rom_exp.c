#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char *argv[])
{
	if (argc != 3)
		return 1;
	int ch = atol(argv[1]), n = atol(argv[2]);
	if (!n)
		return 1;

	printf("WIDTH=%u;\n", n * 2);
	printf("DEPTH=%u;\n\n", 800);
	puts("ADDRESS_RADIX=DEC;");
	puts("DATA_RADIX=HEX;\n");
	puts("CONTENT BEGIN");
	unsigned long i;
	for (i = 0; i != 800; i++) {
		double w = -M_PI * 2.f * (double)i * (double)ch / 800.f;
		long re = round(cos(w) * pow(2.0, n - 1));
		long im = round(sin(w) * pow(2.0, n - 1));
		re = re & ((1ul << n) - 1);
		im = im & ((1ul << n) - 1);
		unsigned long v = (im << n) | re;
		printf("\t%lu : %lx;\n", i, v);
	}
	puts("END;");
}
