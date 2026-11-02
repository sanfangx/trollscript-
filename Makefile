TARGET = libPhotoModule.dylib
SDK = $(shell xcrun --sdk iphoneos --show-sdk-path)

CC = clang
CFLAGS = -dynamiclib -arch arm64 -isysroot $(SDK) -miphoneos-version-min=14.0 -fobjc-arc -I./src
LDFLAGS = -framework Foundation -framework UIKit -framework Photos -undefined dynamic_lookup -install_name @executable_path/Frameworks/$(TARGET)

SRCS = src/fishhook.c src/TSPhotoHelper.m src/PhotoModuleBridge.m

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $(SRCS) $(LDFLAGS) -o $@
	@if command -v ldid >/dev/null 2>&1; then ldid -S $@; else codesign -s - $@; fi
	@echo "Build complete: $@"

clean:
	rm -f $(TARGET)

.PHONY: all clean
