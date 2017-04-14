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

	unsigned long i;
	for (i = 0; i != n; i++) {
		double w = -M_PI * (double)i / (double)n;
		double re = cos(w) * pow(2.0, frac);
		double im = sin(w) * pow(2.0, frac);
		printf("'{%.0f, %.0f}%s\n", round(re), round(im),
			i == n - 1 ? "" : ",");
	}
}
