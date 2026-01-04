import Cocoa

guard CommandLine.arguments.count == 3 else {
    print("Usage: CircleMask <input_path> <output_path>")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let image = NSImage(contentsOfFile: inputPath) else {
    print("Failed to load image at \(inputPath)")
    exit(1)
}

let size = NSSize(width: 1024, height: 1024)
let targetRect = NSRect(origin: .zero, size: size)

let finalImage = NSImage(size: size)
finalImage.lockFocus()

let context = NSGraphicsContext.current!.cgContext

// Clear background
context.clear(targetRect)

// Geometry
// Make the earth slightly smaller to fit shadow
let earthDiameter: CGFloat = 920
let margin = (1024 - earthDiameter) / 2
let earthRect = NSRect(x: margin, y: margin + 20, width: earthDiameter, height: earthDiameter) // Shift up slightly for shadow

// Draw Shadow
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
shadow.shadowOffset = NSSize(width: 0, height: -15)
shadow.shadowBlurRadius = 30

context.saveGState()
shadow.set()
NSColor.white.setFill() // Shadow needs something to cast from
let shadowPath = NSBezierPath(ovalIn: earthRect)
shadowPath.fill()
context.restoreGState()

// Draw Earth with Circle Mask
NSGraphicsContext.current?.saveGraphicsState()
let clipPath = NSBezierPath(ovalIn: earthRect)
clipPath.addClip()

// Draw original image centered and properly scaled
image.draw(in: earthRect, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1.0)

NSGraphicsContext.current?.restoreGraphicsState()

finalImage.unlockFocus()

// Save to PNG
guard let tiffData = finalImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to create PNG data")
    exit(1)
}

try? pngData.write(to: URL(fileURLWithPath: outputPath))
print("Successfully created transparent icon at \(outputPath)")
