import AVFoundation

let asset = AVURLAsset(url: URL(filePath: "output.mp4"))
print(asset.duration)
