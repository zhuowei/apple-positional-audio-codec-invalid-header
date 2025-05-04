#!/bin/bash
set -e
python3 gen_stsb_with_cookie.py stsb_unmodified_hoa.bin apac_cookie.bin stsb_with_cookie.bin
mp4edit --replace moov/trak[0]/mdia/minf/stbl/stsd/apac:stsb_with_cookie.bin output_unmodified_hoa.mp4 output.mp4
