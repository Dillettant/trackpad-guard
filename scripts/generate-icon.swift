#!/usr/bin/env swift
import Cocoa

// Generate a TrackpadGuard app icon: a trackpad with a shield/slash overlay
let size = CGSize(width: 1024, height: 1024)

let image = NSImage(size: size, flipped: false) { rect in
    let ctx = NSGraphicsContext.current!.cgContext

    // Background: rounded rectangle with gradient
    let bgPath = CGPath(roundedRect: rect.insetBy(dx: 80, dy: 80),
                        cornerWidth: 180, cornerHeight: 180,
                        transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    // Gradient background
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorsSpace: colorSpace,
                              colors: [
                                NSColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1).cgColor,
                                NSColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1).cgColor
                              ] as CFArray,
                              locations: [0, 1])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 512, y: 944),
                           end: CGPoint(x: 512, y: 80),
                           options: [])

    // Trackpad body (rounded rect)
    let trackpadRect = CGRect(x: 280, y: 250, width: 464, height: 520)
    let trackpadPath = CGPath(roundedRect: trackpadRect, cornerWidth: 40, cornerHeight: 40, transform: nil)
    ctx.setFillColor(NSColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 1).cgColor)
    ctx.addPath(trackpadPath)
    ctx.fillPath()

    // Trackpad inner surface
    let innerRect = trackpadRect.insetBy(dx: 20, dy: 20)
    let innerPath = CGPath(roundedRect: innerRect, cornerWidth: 25, cornerHeight: 25, transform: nil)
    ctx.setFillColor(NSColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1).cgColor)
    ctx.addPath(innerPath)
    ctx.fillPath()

    // Divider line (click area)
    ctx.setStrokeColor(NSColor(red: 0.7, green: 0.7, blue: 0.73, alpha: 1).cgColor)
    ctx.setLineWidth(3)
    ctx.move(to: CGPoint(x: 320, y: 350))
    ctx.addLine(to: CGPoint(x: 704, y: 350))
    ctx.strokePath()

    // Shield/guard circle
    let circleCenter = CGPoint(x: 620, y: 360)
    let circleRadius: CGFloat = 140
    ctx.setFillColor(NSColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 0.9).cgColor)
    ctx.fillEllipse(in: CGRect(x: circleCenter.x - circleRadius,
                                y: circleCenter.y - circleRadius,
                                width: circleRadius * 2,
                                height: circleRadius * 2))

    // Slash through circle
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(18)
    ctx.setLineCap(.round)
    let slashOffset: CGFloat = circleRadius * 0.65
    ctx.move(to: CGPoint(x: circleCenter.x - slashOffset, y: circleCenter.y - slashOffset))
    ctx.addLine(to: CGPoint(x: circleCenter.x + slashOffset, y: circleCenter.y + slashOffset))
    ctx.strokePath()

    // Hand silhouette (simplified)
    ctx.setFillColor(NSColor.white.cgColor)
    // Palm
    let palmRect = CGRect(x: circleCenter.x - 45, y: circleCenter.y - 50, width: 90, height: 70)
    let palmPath = CGPath(roundedRect: palmRect, cornerWidth: 20, cornerHeight: 20, transform: nil)
    ctx.addPath(palmPath)
    ctx.fillPath()

    // Fingers (3 simple rectangles)
    for i in 0..<3 {
        let fingerX = circleCenter.x - 35 + CGFloat(i) * 30
        let fingerRect = CGRect(x: fingerX, y: circleCenter.y + 15, width: 18, height: 45)
        let fingerPath = CGPath(roundedRect: fingerRect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        ctx.addPath(fingerPath)
        ctx.fillPath()
    }

    // Re-draw the slash on top
    ctx.setStrokeColor(NSColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 1).cgColor)
    ctx.setLineWidth(12)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: circleCenter.x - slashOffset, y: circleCenter.y - slashOffset))
    ctx.addLine(to: CGPoint(x: circleCenter.x + slashOffset, y: circleCenter.y + slashOffset))
    ctx.strokePath()

    return true
}

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to generate image")
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png"

try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Icon saved to \(outputPath)")
