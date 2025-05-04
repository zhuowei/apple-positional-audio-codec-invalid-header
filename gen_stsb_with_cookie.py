import sys
import struct

with open(sys.argv[1], "rb") as infile:
	indata = infile.read()

# length, atom type, common audio header
# starts
# https://source.chromium.org/chromium/chromium/src/+/main:third_party/ffmpeg/libavformat/movenc.c;l=1370;drc=2229b741273818dc722a2bfcb6410067902b514c
# ends
# https://source.chromium.org/chromium/chromium/src/+/main:third_party/ffmpeg/libavformat/movenc.c;l=1442;drc=2229b741273818dc722a2bfcb6410067902b514c
common_audio_header_length = 4 + 4 + 0x1c
common_audio_header = indata[:common_audio_header_length]

with open(sys.argv[2], "rb") as infile:
	indata2 = infile.read()

output_bytes = bytearray(common_audio_header + indata2)

output_bytes[0:4] = struct.pack(">I", len(output_bytes))

with open(sys.argv[3], "wb") as outfile:
	outfile.write(output_bytes)
