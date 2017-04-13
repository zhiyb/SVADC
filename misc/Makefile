CFLAGS	+= -O3
LDFLAGS	+= -O3 -lm

all: rom_sin_4_5.mif rom_test_lines.mif

.DELETE_ON_ERROR:

rom_sin_4_%.mif: rom_sin
	./$^ 4 $* > $@

rom_%.mif: rom_%
	./$^ > $@

rom_%: rom_%.o
	$(CC) -o $@ $< $(LDFLAGS)
