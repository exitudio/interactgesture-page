import Foundation
import CoreGraphics
import ImageIO

guard CommandLine.arguments.count == 4,
      let targetWidth = Int(CommandLine.arguments[3]) else {
    fputs("Usage: render-pdf input.pdf output.png width\n", stderr)
    exit(1)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2]) as CFURL

guard let document = CGPDFDocument(inputURL),
      let page = document.page(at: 1) else {
    fputs("Could not open PDF\n", stderr)
    exit(1)
}

let box = page.getBoxRect(.mediaBox)
let scale = CGFloat(targetWidth) / box.width
let targetHeight = Int(ceil(box.height * scale))

guard let context = CGContext(
    data: nil,
    width: targetWidth,
    height: targetHeight,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Could not create bitmap context\n", stderr)
    exit(1)
}

context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
context.saveGState()
context.scaleBy(x: scale, y: scale)
context.translateBy(x: -box.minX, y: -box.minY)
context.drawPDFPage(page)
context.restoreGState()

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(outputURL, "public.png" as CFString, 1, nil) else {
    fputs("Could not create PNG destination\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("Could not write PNG\n", stderr)
    exit(1)
}

print("Rendered \(targetWidth)x\(targetHeight)")
