#include <stdio.h>
#include <stdlib.h>
#include <math.h>

double c(int k, int n, int m)
{
	return cos(M_PI * 2.f * (double)k * (double)n / (double)m);
}

int main(int argc, char *argv[])
{
	if (argc != 3)
		return 1;
	unsigned long frac = atoi(argv[1]), m = atoi(argv[2]);
	if (m == 0)
		return 1;

	int n;
	for (n = -m / 2; n != m / 2; n++) {
		double w = 0.42f + 0.5f * c(1, n, m) + 0.08 * c(2, n, m);
		w *= pow(2, frac);
		printf("%.0f%s\n", round(w), n == m / 2 - 1 ? "" : ",");
	}
}
