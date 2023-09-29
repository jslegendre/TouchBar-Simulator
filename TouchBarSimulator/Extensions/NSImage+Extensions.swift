//
//  NSImage+Extensions.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 9/26/23.
//

import Foundation

public extension NSImage {
    func rotate(degrees:CGFloat) -> NSImage {
        
        var imageBounds = NSZeroRect ; imageBounds.size = self.size
        let pathBounds = NSBezierPath(rect: imageBounds)
        let pathTransform = AffineTransform(rotationByDegrees: degrees)
        pathBounds.transform(using: pathTransform)
        let rotatedBounds:NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y, pathBounds.bounds.size.width, pathBounds.bounds.size.height )
        let rotatedImage = NSImage(size: rotatedBounds.size)
        
        //Center the image within the rotated bounds
        imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
        imageBounds.origin.y  = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)
        
        // Start a new transform
        let imageTransform = NSAffineTransform()
        // Move coordinate system to the center (since we want to rotate around the center)
        imageTransform.translateX(by: +(NSWidth(rotatedBounds) / 2 ), yBy: +(NSHeight(rotatedBounds) / 2))
        imageTransform.rotate(byDegrees: degrees)
        // Move the coordinate system bak to normal
        imageTransform.translateX(by: -(NSWidth(rotatedBounds) / 2 ), yBy: -(NSHeight(rotatedBounds) / 2))
        // Draw the original image, rotated, into the new image
        rotatedImage.lockFocus()
        imageTransform.concat()
        self.draw(in: imageBounds, from: NSZeroRect, operation: .copy, fraction: 1.0)
        rotatedImage.unlockFocus()
        
        return rotatedImage
    }
}
