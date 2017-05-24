#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define F0	(140ul * 1000ul)
#define FSMPL	(400ul * 1000ul)
#define M	18u

double c(int k, int m, double n)
{
	return cos(2.0 * M_PI * (double)k * n / ((double)m + 1.0));
}

int main(int argc, char *argv[])
{
	if (argc != 2)
		return 1;
	unsigned long frac = atoi(argv[1]);
	if (!frac)
		return 1;

	double w0 = 2.0 * M_PI * (double)F0 / (double)FSMPL;
	unsigned long i;
	for (i = 0; i != M / 2; i++) {
		double n = -(double)(M - 1) / 2.0 + (double)i;
		double h = (n * w0 * cos(n * w0) - sin(n * w0)) / (M_PI * n * n);
		double w = 0.42 + 0.5 * c(1, M, n) + 0.08 * c(2, M, n);
		double hw = h * w;
		long hwi = round(hw * pow(2.0, frac));
		printf("%ld%s\n", hwi, i == M / 2 - 1 ? "" : ",");
		//fprintf(stderr, "%lu: %g -> %g => %g / %ld\n", i, n, h, hw, hwi);
	}
}
