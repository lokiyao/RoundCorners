import AppKit
import SwiftUI
import Foundation
let folder = "work/AppIcon.iconset"
try! FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
for (name, size) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
 let rep = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:size,pixelsHigh:size,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 let ctx = NSGraphicsContext(bitmapImageRep:rep)!
 NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ctx
 let c = ctx.cgContext
 c.scaleBy(x:CGFloat(size)/1024,y:CGFloat(size)/1024)
 let bg = RoundedRectangle(cornerRadius:190,style:.continuous).path(in:CGRect(x:70,y:70,width:884,height:884)).cgPath
 c.addPath(bg);c.setFillColor(NSColor(srgbRed:0.13,green:0.15,blue:0.19,alpha:1).cgColor);c.fillPath()
 c.setStrokeColor(NSColor(srgbRed:234/255,green:190/255,blue:187/255,alpha:1).cgColor)
 c.setLineWidth(52);c.setLineCap(.round)
 for (x,y,sx,sy) in [(260.0,260.0,1.0,1.0),(764,260,-1,1),(260,764,1,-1),(764,764,-1,-1)] {
  c.saveGState();c.translateBy(x:x,y:y);c.scaleBy(x:sx,y:sy)
  c.move(to:CGPoint(x:0,y:175));c.addLine(to:CGPoint(x:0,y:90));c.addCurve(to:CGPoint(x:90,y:0),control1:CGPoint(x:0,y:18),control2:CGPoint(x:18,y:0));c.addLine(to:CGPoint(x:175,y:0));c.strokePath();c.restoreGState()
 }
 NSGraphicsContext.restoreGraphicsState()
 try! rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"\(folder)/\(name).png"))
}
