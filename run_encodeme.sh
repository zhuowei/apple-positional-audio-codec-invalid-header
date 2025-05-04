set -e
rm output_unmodified_hoa.mp4 stsb_unmodified_hoa.bin stsb_unmodified_hoa_original_header.bin || true
lldb ./encodeme --source run_encodeme_hook.lldb --batch
mp4extract moov/trak[0]/mdia/minf/stbl/stsd/apac output_unmodified_hoa.mp4 stsb_unmodified_hoa.bin
