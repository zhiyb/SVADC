CFLAGS	+= -O3
LDFLAGS	+= -O3 -lm

FRAC	= 5
SEQ	= 1 2 4 8 16 32 64 128

all: $(SEQ:%=exp%.sv) $(SEQ:%=window_bh_%.sv)

.DELETE_ON_ERROR:

window_bh_%.sv: window_bh Makefile
	./$< $(FRAC) $* > $@

exp%.sv: exp Makefile
	./$< $(FRAC) $* > $@

exp window_bh: %: %.o
	$(CC) -o $@ $< $(LDFLAGS)
