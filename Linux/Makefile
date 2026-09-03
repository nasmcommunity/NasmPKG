AS := nasm
ASFLAGS := -f elf64 -g -F dwarf -I src/ -I src/tls/
LD := ld
BIN := nasmpkg

all: $(BIN)

build:
	mkdir -p build

build/main.o: src/main.asm | build
	$(AS) $(ASFLAGS) src/main.asm -o $@

$(BIN): build/main.o
	$(LD) $< -o $(BIN)

clean:
	rm -rf build $(BIN)

.PHONY: all clean
