CC := $(shell xcrun --find clang)
SDK := $(shell xcrun --sdk macosx --show-sdk-path)
OUT ?= ../build
FLAGS := -isysroot $(SDK) -mmacosx-version-min=27.0 -fobjc-arc -fblocks -O2 -Wall -Wextra
FRAMEWORKS := -framework AppKit -framework Foundation -framework QuartzCore -framework CoreGraphics
# WindowManager is arm64e. The others are for apps launched while DYLD_INSERT_LIBRARIES is set:
# without a matching slice they die at launch.
ARCHS := -arch arm64e -arch arm64 -arch x86_64

.PHONY: plugin
plugin: $(OUT)/spaces-renamer.dylib

$(OUT):
	mkdir -p $@

$(OUT)/spaces-renamer.dylib: spacesRenamer.m Makefile | $(OUT)
	$(CC) $(FLAGS) $(ARCHS) -dynamiclib $(FRAMEWORKS) -o $@ $<
	codesign --force --sign - $@
