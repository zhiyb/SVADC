CFLAGS	+= -O3
LDFLAGS	+= -O3 -lm

CH	= 91

all: rom_exp_10.mif

.DELETE_ON_ERROR:

rom_exp_%.mif: rom_exp
	./$< $(CH) $* > $@

exp rom_exp window_bh: %: %.o
	$(CC) -o $@ $< $(LDFLAGS)
