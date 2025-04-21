import AVFAudio

// https://github.com/robertncoomber/NativeiOSAmbisonicPlayback/blob/main/NativeiOSAmbisonicPlayback/Code/AmbisonicPlayback.swift#L37

let formatIn = AVAudioFormat(
  commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!

var outputDescription = AudioStreamBasicDescription(
  mSampleRate: 44100,
  mFormatID: kAudioFormatAPAC,
  mFormatFlags: 0,
  mBytesPerPacket: 0,
  mFramesPerPacket: 0,
  mBytesPerFrame: 0,
  mChannelsPerFrame: 16,
  mBitsPerChannel: 0,
  mReserved: 0)
let channelLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_HOA_ACN_SN3D | 16)!
let formatOut = AVAudioFormat(streamDescription: &outputDescription, channelLayout: channelLayout)!

guard let converter = AVAudioConverter(from: formatIn, to: formatOut) else {
  print("no converter")
  exit(0)
}
let magicCookie = converter.magicCookie!
try! magicCookie.write(to: URL(filePath: "apac_hoa.dat"))
