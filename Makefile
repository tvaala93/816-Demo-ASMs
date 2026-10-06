CPU     := 65816
LIBDIR  := lib
BUILD   := build
BIN		:= bin
CFG     := rom.cfg
TARGET  := $(BIN)/helloNewWorld.bin

# Add new lib/*.s files here as you create them (e.g. serial.s)
OBJECTS := $(BUILD)/helloNewWorld.o \
           $(BUILD)/thruHoleUtils.o \
           $(BUILD)/lcd.o

.PHONY: all clean

all: $(TARGET)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/helloNewWorld.o: helloNewWorld.s | $(BUILD)
	ca65 --cpu $(CPU) -o $@ $<

$(BUILD)/%.o: $(LIBDIR)/%.s | $(BUILD)
	ca65 --cpu $(CPU) -o $@ $<

$(TARGET): $(OBJECTS) $(CFG)
	ld65 -C $(CFG) -o $(TARGET) $(OBJECTS)

clean:
	rm -rf $(BUILD)