KERNEL := vinix.elf

OBJDUMP = objdump
CC = cc
V = v

CFLAGS =                          \
	-O2 -g -pipe -Wall -Wextra    \
	-Wno-unused-parameter         \
	-Wno-unused-function          \
	-Wno-unused-variable          \
	-Wno-unused-but-set-variable  \
	-Wno-div-by-zero              \
	-Wno-missing-braces           \
	-Wno-address-of-packed-member

INTERNALCFLAGS :=           \
	-I.                     \
	-ffreestanding          \
	-fno-omit-frame-pointer \
	-fno-stack-protector    \
	-fno-pic -fpie          \
	-ffunction-sections     \
	-fdata-sections         \
	-fno-inline             \
	-fwhole-program         \
	-mgeneral-regs-only     \
	-mno-red-zone           \
	-static-pie             \
	-nostdlib               \
	-Tlinker.ld             \
	-Wl,-gc-sections        \
	-z max-page-size=0x1000

INTERNALVFLAGS :=   \
	-shared         \
	-enable-globals \
	-d no_backtrace

VFILES := $(shell find ./ -type f -name '*.v')
CFILES := $(shell find ./ -type f -name '*.c')

.PHONY: all
all: $(KERNEL)

.PHONY:
clean:
	rm -rf $(KERNEL) blob modules/lib/symbol.v

$(KERNEL):
	cp dummy_symbol_table modules/lib/symbol.v
	$(MAKE) blob
	$(CC) -x c $(CFLAGS) $(INTERNALCFLAGS) blob -o $@
	./gensyms.sh $(OBJDUMP) $@ > modules/lib/symbol.v
	$(MAKE) blob
	$(CC) -x c $(CFLAGS) $(INTERNALCFLAGS) blob -o $@

.PHONY:
blob: $(VFILES) $(CFILES)
	$(V) $(VFLAGS) $(INTERNALVFLAGS) -o vblob.c .
	printf '#define double int\n#define float int\n' \
		| cat - $(CFILES) vblob.c \
		| sed 's/void main__kmain(/__attribute__((externally_visible)) void main__kmain(/g' \
		> blob
	rm vblob.c
