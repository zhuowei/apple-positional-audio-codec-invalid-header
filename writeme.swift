import AVFAudio

func run() {
  var outputDescription = AudioStreamBasicDescription(
    mSampleRate: 44100,
    mFormatID: kAudioFormatAPAC,
    mFormatFlags: 0,
    mBytesPerPacket: 1024,
    mFramesPerPacket: 0,
    mBytesPerFrame: 0,
    mChannelsPerFrame: 4,
    mBitsPerChannel: 0,
    mReserved: 0)

  var audioFile: AudioFileID! = nil
  var status: OSStatus = 0

  status = AudioFileCreateWithURL(
    URL(filePath: "writeme.mp4") as CFURL, kAudioFileMPEG4Type, &outputDescription,
    AudioFileFlags.eraseFile, &audioFile)
  if status != 0 {
    print(String(format: "failed to open: %x", status))
    return
  }

  let magicCookie = try! Data(contentsOf: URL(filePath: "apac_cookie.bin"))
  magicCookie.withUnsafeBytes {
    status = AudioFileSetProperty(
      audioFile, kAudioFilePropertyMagicCookieData, UInt32($0.count), $0.baseAddress!)
  }

  if status != 0 {
    print(String(format: "failed to cookie: %x", status))
    return
  }

  let outBytes = Data(count: 1024)
  outBytes.withUnsafeBytes {
    var numBytes: UInt32 = UInt32($0.count)
    status = AudioFileWriteBytes(audioFile, false, 0, &numBytes, $0.baseAddress!)
  }
  if status != 0 {
    print(String(format: "failed to write: %x", status))
    return
  }

  status = AudioFileClose(audioFile)
  if status != 0 {
    print(String(format: "failed to close: %x", status))
    return
  }
}

run()
