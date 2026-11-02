#!/bin/bash
set -e

echo "=== Building libPhotoModule.dylib for iOS arm64 ==="

SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)

clang -dynamiclib -arch arm64 \
    -isysroot "$SDK_PATH" \
    -miphoneos-version-min=14.0 \
    -fobjc-arc \
    -framework Foundation \
    -framework UIKit \
    -framework Photos \
    -I./src \
    src/fishhook.c \
    src/TSPhotoHelper.m \
    src/PhotoModuleBridge.m \
    -undefined dynamic_lookup \
    -install_name @executable_path/Frameworks/libPhotoModule.dylib \
    -o libPhotoModule.dylib

echo "=== Signing libPhotoModule.dylib with ldid ==="
if command -v ldid &> /dev/null; then
    ldid -S libPhotoModule.dylib
elif command -v codesign &> /dev/null; then
    codesign -s - libPhotoModule.dylib
fi

echo "Build successful! Output: libPhotoModule.dylib"
