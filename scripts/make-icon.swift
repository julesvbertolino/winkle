#!/usr/bin/env swift
// Génère l'icône de Winkle : un œil periwinkle lumineux sur fond navy dégradé,
// dans le squircle macOS. Rend un PNG 1024×1024 ; scripts/make-icns.sh en tire le .icns.
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no context") }

// Squircle macOS : rayon ≈ 22,37 % du côté.
let inset: CGFloat = 0
let rect = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let radius = size * 0.2237
let squircle = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()

// Fond : dégradé navy (#16213f → #101a35 → #0c142a), du haut-gauche vers le bas-droite.
let navy: [CGFloat] = [
    0.086, 0.129, 0.247, 1,
    0.063, 0.102, 0.208, 1,
    0.047, 0.078, 0.165, 1,
]
let space = CGColorSpaceCreateDeviceRGB()
if let grad = CGGradient(colorSpace: space, colorComponents: navy, locations: [0, 0.55, 1], count: 3) {
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
}

// Halo periwinkle derrière l'œil (la signature lumineuse).
let glow: [CGFloat] = [0.663, 0.761, 1.0, 0.55,  0.663, 0.761, 1.0, 0.0]
if let glowGrad = CGGradient(colorSpace: space, colorComponents: glow, locations: [0, 1], count: 2) {
    let center = CGPoint(x: size * 0.5, y: size * 0.5)
    ctx.drawRadialGradient(glowGrad, startCenter: center, startRadius: 0,
                           endCenter: center, endRadius: size * 0.42, options: [])
}

ctx.restoreGState()

// L'œil : arc doux (clin d'œil), même géométrie que l'app.
let eye = NSBezierPath()
eye.move(to: NSPoint(x: size * 0.24, y: size * 0.44))
eye.curve(to: NSPoint(x: size * 0.76, y: size * 0.44),
          controlPoint1: NSPoint(x: size * 0.40, y: size * 0.70),
          controlPoint2: NSPoint(x: size * 0.60, y: size * 0.70))
eye.lineWidth = size * 0.058
eye.lineCapStyle = .round

// Légère ombre portée bleutée pour le relief.
ctx.setShadow(offset: .zero, blur: size * 0.03,
              color: NSColor(red: 0.663, green: 0.761, blue: 1.0, alpha: 0.8).cgColor)
NSColor(red: 0.765, green: 0.835, blue: 1.0, alpha: 1.0).setStroke() // #c3d5ff
eye.stroke()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("PNG encoding failed")
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
try! png.write(to: URL(fileURLWithPath: out))
print("✓ \(out)")
