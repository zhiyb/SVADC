#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define DEPTH	16

#define X	0
#define Y	1
#define R	0
#define G	1
#define B	2

static struct line_t {
	unsigned long start[2], end[2];
	unsigned char clr[3];
} line[DEPTH] = {
	//	\7|3/
	//	6\|/2
	//	--o-- x
	//	4/|\0
	//	/5|1\
	//	  y
	// {10, 205, 400, 595, 790}, {10, 125, 240, 355, 470}
	{{410, 245}, {790, 335},	{0xff, 0x00, 0x00}},	// 0
	{{405, 250}, {595, 470},	{0xff, 0xff, 0x00}},	// 1
	{{410, 235}, {790, 205},	{0x00, 0xff, 0x00}},	// 2
	{{405, 230}, {595, 10},		{0x00, 0xff, 0xff}},	// 3
	{{390, 245}, {10, 335},		{0x00, 0x00, 0xff}},	// 4
	{{395, 250}, {205, 470},	{0xff, 0x00, 0xff}},	// 5
	{{390, 235}, {10, 205},		{0xff, 0xff, 0xff}},	// 6
	{{395, 230}, {205, 10},		{0x7f, 0x7f, 0x7f}},	// 7

	{{10, 0}, {790, 0},		{0xff, 0x7f, 0x00}},	// 8
	{{799, 10}, {799, 470},		{0x00, 0xff, 0x7f}},	// 9
	{{790, 479}, {10, 479},		{0x7f, 0x00, 0xff}},	// a
	{{0, 470}, {0, 10},		{0x7f, 0xff, 0x00}},	// b

	{{400, 240}, {400, 240},	{0x66, 0xcc, 0xff}},	// c
	{{400, 30}, {580, 450},		{0xff, 0x3f, 0x00}},	// d
	{{580, 450}, {220, 450},	{0x00, 0xff, 0x3f}},	// e
	{{220, 450}, {400, 30},		{0x3f, 0x00, 0xff}},	// f
};

int main(int argc, char *argv[])
{
	printf("WIDTH=%u;\n", 54);
	printf("DEPTH=%u;\n\n", DEPTH);
	puts("ADDRESS_RADIX=DEC;");
	puts("DATA_RADIX=HEX;\n");
	puts("CONTENT BEGIN");
	struct line_t *p = line;
	unsigned long i;
	for (i = 0; i != DEPTH; i++, p++) {
		unsigned long v = ((p->start[X] & 0x03ff) << 44) |
			((p->start[Y] & 0x01ff) << 35) |
			((p->end[X] & 0x03ff) << 25) |
			((p->end[Y] & 0x01ff) << 16) |
			((p->clr[R] >> 3) << 11) |
			((p->clr[G] >> 2) << 5) | (p->clr[B] >> 3);
		printf("\t%lu : %lx;\n", i, v);
	}
	puts("END;");
}
