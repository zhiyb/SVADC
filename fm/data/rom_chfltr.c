#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define FSB	(100ul * 1000ul)
#define FSMPL	(80ul * 1000ul * 1000ul)

double c(int k, int m, int n)
{
	return cos(2.0 * M_PI * (double)k * (double)n / ((double)m + 1.0));
}

int main(int argc, char *argv[])
{
	if (argc != 1 + 5)
		return 1;
	int s = atoi(argv[1]), p = atoi(argv[2]);
	int strip = atoi(argv[3]), dw = atoi(argv[4]), frac = atoi(argv[5]);
	const int m = s * p;
	if (!m || !strip || !dw)
		return 1;
	strip--;

	printf("WIDTH=%d;\n", dw);
	printf("DEPTH=%d;\n\n", p);
	puts("ADDRESS_RADIX=DEC;");
	puts("DATA_RADIX=HEX;\n");
	puts("CONTENT BEGIN");
	double w0 = 2.0 * M_PI * (double)FSB / (double)FSMPL;
	unsigned long i;
	for (i = 0; i != p; i++) {
		const int n = -m / 2 + strip * p + i;
		double w = 0.42 + 0.5 * c(1, m, n) + 0.08 * c(2, m, n);
		double h = sin(w0 * (double)n) / (M_PI * (double)n);
		if (n == 0)
			h = w0 / M_PI;
		h = h / (w0 / M_PI) / 1.05;
		double hw = h * w * pow(2.0, frac);
		long hwi = round(hw);
		//fprintf(stderr, "%d: %g, %g -> %g => %ld\n", n, h, w, hw, hwi);
		printf("\t%lu : %lx;\n", i, hwi & ((1ul << dw) - 1ul));
	}
	puts("END;");
	return 0;
}
