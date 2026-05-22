ROMNAME = gameoflife.sfc

# Assembler and Linker
AS      = wla-65816
LINK    = wlalink

# Emulator (Mesen)
EMU     = /Applications/Mesen.app/Contents/MacOS/Mesen

# Object files to build
OBJS    = main.o

# Flags
ASFLAGS = -v -o 

# -s = create symbol file (.sym) for debugging
# -r = make the linker use the link file
LINKFLAGS = -s -r

# Default target: Build the ROM
all: $(ROMNAME)

# 1. LINKING
$(ROMNAME): $(OBJS)
	@echo "Linking $(ROMNAME)..."
	@echo "[objects]" > linkfile
	@echo "$(OBJS)" >> linkfile
	$(LINK) $(LINKFLAGS) linkfile $@

# 2. ASSEMBLING
main.o: main.asm header.inc InitSNES.asm
	@echo "Assembling main.asm..."
	$(AS) $(ASFLAGS) $@ $< 

# Run the game in bsnes-plus
run: $(ROMNAME)
	@echo "Launching Emulator..."
	$(EMU) $(abspath $(ROMNAME))

clean:
	rm -f *.o *.sfc *.sym *.chr linkfile

.PHONY: all run clean