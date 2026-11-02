#!/bin/bash
set -ex

echo "=== Finding iPhoneOS SDK ==="
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
echo "Using SDK: $SDK_PATH"

echo "=== Compiling libPhotoModule.dylib for iOS arm64 ==="
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
    -install_name @executable_path/Frameworks/libPhotoModule.dylib \
    -o libPhotoModule.dylib

echo "=== Signing libPhotoModule.dylib ==="
if command -v ldid &> /dev/null; then
    ldid -S libPhotoModule.dylib
elif command -v codesign &> /dev/null; then
    codesign -s - libPhotoModule.dylib
fi

echo "Build successful! Output: libPhotoModule.dylib"
file libPhotoModule.dylib
