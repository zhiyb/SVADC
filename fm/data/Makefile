CFLAGS	+= -O3
LDFLAGS	+= -O3 -lm

CH	= 91

# Filter constants precision
PREC	= 9
# Filter fixed precision fractional part
FRAC	= 8
CHFLTR	:= $(shell seq 1 6)
CHFLTR	:= $(CHFLTR:%=rom_chfltr_%.mif)

all: rom_exp_10.mif $(CHFLTR)

.DELETE_ON_ERROR:

rom_exp_%.mif: rom_exp
	./$< $(CH) $* > $@

rom_chfltr_%.mif: rom_chfltr
	./$< 6 200 $* $(PREC) $(FRAC) > $@

rom_exp rom_chfltr: %: %.o
	$(CC) -o $@ $< $(LDFLAGS)
