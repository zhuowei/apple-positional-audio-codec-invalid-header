#!/bin/sh
lipo -thin arm64e /usr/bin/afconvert -output afconvert_arm64e
dd if=/dev/zero bs=4 seek=2 count=1 of=afconvert_arm64e conv=notrunc
codesign --sign - -f afconvert_arm64e
