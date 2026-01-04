import Cocoa

guard CommandLine.arguments.count == 3 else {
    print("Usage: IconComposition <input_path> <output_path>")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let image = NSImage(contentsOfFile: inputPath) else {
    print("Failed to load image at \(inputPath)")
    exit(1)
}

// Icon size
let size = NSSize(width: 512, height: 512)
let targetRect = NSRect(origin: .zero, size: size)

let finalImage = NSImage(size: size)
finalImage.lockFocus()

let context = NSGraphicsContext.current!.cgContext

// 1. Fill White Background
NSColor.white.setFill()
context.fill(targetRect)

// 2. Draw Earth (Smaller)
// Original requirement was "smaller proportion in the box"
// Let's make it about 80% of the width
let earthDiameter: CGFloat = size.width * 0.82
let margin = (size.width - earthDiameter) / 2
// Center vertically, maybe slightly up to look balanced if we had shadow, but centering is safe
let earthRect = NSRect(x: margin, y: margin, width: earthDiameter, height: earthDiameter)

// Draw original image centered and scaled
image.draw(in: earthRect, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1.0)

finalImage.unlockFocus()

// Save to PNG
guard let tiffData = finalImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to create PNG data")
    exit(1)
}

try? pngData.write(to: URL(fileURLWithPath: outputPath))
print("Successfully created composited icon at \(outputPath)")
