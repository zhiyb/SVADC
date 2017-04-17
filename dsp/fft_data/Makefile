CFLAGS	+= -O3
LDFLAGS	+= -O3 -lm

FRAC	= 5
SEQ	= 1 2 4 8 16 32 64 128 256 512 1024 2048 4096

all: $(SEQ:%=exp%.sv) $(SEQ:%=window_bh_%.sv) $(SEQ:%=rom_exp%.mif)

.DELETE_ON_ERROR:

window_bh_%.sv: window_bh Makefile
	./$< $(FRAC) $* > $@

exp%.sv: exp Makefile
	./$< $(FRAC) $* > $@

rom_exp%.mif: rom_exp
	./$< $(FRAC) $* > $@

exp rom_exp window_bh: %: %.o
	$(CC) -o $@ $< $(LDFLAGS)
