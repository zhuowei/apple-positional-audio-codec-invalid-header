Proof-of-concept for the CoreAudio patch (CVE-2025-31200) in [iOS 18.4.1](https://support.apple.com/en-us/122282).

# Update 05/21/2025
I @noahhw46 (couldn't have done it without this setup @zhouwei) figured it out (writeup coming soon). However, there is still a lot more to understand. I added the first bit of the next steps of my investigation here in order to show exactly what the bug *does*. check-mismatch is another lldb script that can be used with a working poc to show exactly the mismatch that was created between the mRemappingArray and the [permutation](https://stackoverflow.com/a/16501453) map in `APACChannelRemapper::Process` (really in `APACHOADecoder::DecodeAPACFrame`).

----

```
The mRemappingArray is sized based on the lower two bytes of mChannelLayoutTag.
By creating a mismatch between them, a later stage of processing in APACHOADecoder::DecodeAPACFrame is corrupted.
When the APACHOADecoder goes to process the APAC frame (permute it according to the channel remapping array), 
for some reason it uses a permutation map that is the size given here in 
mChannelLayoutTag, rather than just based on m_totalComponents. 
```

When you play the `output.mp4` audio file (e.g. with AVAudioPlayer), `APACChannelRemapper::Process` will read then write out of bounds.

You can see the first read out of bounds if you enable Guard Malloc in Xcode:

<img width="1024" alt="Xcode displaying crash in APACChannelRemapper::Process" src="https://github.com/user-attachments/assets/c733936b-2b91-43a2-9047-5651b66ce81d" />

Without Guard Malloc, `APACHOADecoder::DecodeAPACFrame` will later crash with an invalid `memmove`:

<img width="1024" alt="Xcode displaying crash in _platform_memmove" src="https://github.com/user-attachments/assets/9fddfbea-e9a8-4672-acf9-c5b193fefe95" />

----

@zhuowei's Previous README is below:


Trying to understand the CoreAudio patch (CVE-2025-31200) in [iOS 18.4.1](https://support.apple.com/en-us/122282).

I haven't figure it out yet.

Currently, I get different error messages when decoding `output.mp4` on macOS 15.4.1:

```
error	01:10:26.743480-0400	getaudiolength	<private>:548    Invalid mRemappingArray bitstream in hoa::CodecConfig::Deserialize()
error	01:10:26.743499-0400	getaudiolength	<private>:860    Error in deserializing ASC components
```

vs Xcode Simulator for visionOS 2.2:

```
error	01:09:21.841805-0400	VisionOSEvaluation	          APACProfile.cpp:424    ERROR: Wrong profile index in GlobalConfig
error	01:09:21.841914-0400	VisionOSEvaluation	     APACGlobalConfig.cpp:894    Profile and level data could not be validated
```

so I am hitting the new check, but I don't know how to get it to actually overwrite something.

## info on the changed function

The changed function [seems](https://github.com/blacktop/ipsw-diffs/blob/main/18_4_22E240__vs_18_4_1_22E252/README.md) to be `apac::hoa::CodecConfig::Deserialize` in `/System/Library/Frameworks/AudioToolbox.framework/AudioCodecs`.

APAC is [Apple Positional Audio Codec](https://support.apple.com/en-by/guide/immersive-video-utility/dev4579429f0/web#:~:text=Apple%20Positional%20Audio%20Codec)

HOA is [Higher-order Ambisonics](https://en.wikipedia.org/wiki/Ambisonics#Higher-order_Ambisonics).

If you look at a [sample file from ffmpeg issue tracker](https://trac.ffmpeg.org/ticket/11480):

```
$ avmediainfo ~/Downloads/clap.MOV 
Asset: /Users/zhuowei/Downloads/clap.MOV
<...>
Track 3: Sound 'soun'
	Enabled: No
	Format Description 1:
		Format: APAC 'apac'
		Channel Layout: High-Order Ambisonics, ACN/SN3D
		Sample rate: 48000.0
		Bytes per packet: 0
		Frames per packet: 1024
		Bytes per frame: 0
		Channels per frame: 4
		Bits per channel: 0
	System support for decoding this track: Yes
	Data size: 43577 bytes
	Media time scale: 48000
	Duration: 0.898 seconds
	Estimated data rate: 363.142 kbit/s
	Extended language tag: und
	1 segment present
	Index   Media Start  Media Duration   Track Start  Track Duration 
	    1  00:00:00.000    00:00:00.898  00:00:00.000    00:00:00.898
	Member of alternate group 0: (2, 3)
```

You can convert to APAC with `afconvert -o sound440.m4a -d apac -f mp4f sound440hz.wav`.

Using `bindiff` on iOS 18.4.1 vs 18.4, it seems reading the `mRemappingArray` now checks the global `AudioChannelLayout*` at offset 0x58 for the number of channels instead of the remapping `AudioChannelLayout*` at offset 0x78.

The `encodeme.mm` file encodes APAC, and an LLDB script forces extra elements into `mRemappingArray` and the remapping `AudioChannelLayout`:

```
./build_encodeme.sh
./run_encodeme.sh
```

