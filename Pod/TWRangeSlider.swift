//
//  TWRangeSlider.swift
//  TWRangeSliderDemo
//
//  Created by kimtaewan on 2016. 1. 15..
//  Copyright © 2016년 carq. All rights reserved.
//

import Foundation
import UIKit

class CircleImage {
    static func getUIImage(radius: CGFloat) -> UIImage {
        let size = CGSizeMake(radius*2, radius*2)
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextFillEllipseInRect(context, rect)
        
        // grab the finished image and return it
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result.imageWithRenderingMode(.AlwaysTemplate)
    }
}

class TrackLayer: CALayer {
    var trackColor = UIColor.lightGrayColor() {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    var highlightColor = UIColor.blueColor() {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    var lowerValue: Double = 0
    var upperValue: Double = 0.5
    
    override func drawInContext(ctx: CGContext) {
        let width = CGRectGetWidth(self.bounds)
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.cornerRadius)
        CGContextAddPath(ctx, path.CGPath)
        
        CGContextSetFillColorWithColor(ctx, trackColor.CGColor)
        CGContextAddPath(ctx, path.CGPath)
        CGContextFillPath(ctx)
        
        CGContextSetFillColorWithColor(ctx, highlightColor.CGColor)
        let x = width * CGFloat(lowerValue)
        let w = max(0, (width * CGFloat(upperValue)) - x)
        let rect = CGRect(x: x, y: 0.0, width: w, height: bounds.height)
        CGContextFillRect(ctx, rect)
    }
}

@IBDesignable
public class TWRangeSlider: UIControl {
    var trackLayer = TrackLayer()
    var lowerThumbView = UIImageView()
    var upperThumbView = UIImageView()
    var touchX: CGFloat = 0
    var moveTartget: UIView?
    
    
    var trackBounds: CGRect {
        let w = CGRectGetWidth(self.bounds)
        let h = CGRectGetHeight(self.bounds)
        let lowerW = CGRectGetWidth(lowerThumbView.bounds)
        let upperW = CGRectGetWidth(upperThumbView.bounds)
        return CGRectMake(lowerW/2, (h - trackHeight)/2, w - (lowerW + upperW)/2, trackHeight)
    }
    
    @IBInspectable public var trackRadius: CGFloat {
        get {
            return trackLayer.cornerRadius
        }
        set(radius) {
            trackLayer.cornerRadius = radius
        }
    }
    
    @IBInspectable public var trackHeight: CGFloat = 4 {
        didSet {
            updateLayer()
        }
    }
    
    @IBInspectable public var trackColor: UIColor {
        get {
            return trackLayer.trackColor
        }
        set(color) {
            trackLayer.trackColor = color
        }
    }
    
    @IBInspectable public var trackHighlightColor: UIColor{
        get {
            return trackLayer.highlightColor
        }
        set(color) {
            trackLayer.highlightColor = color
            upperThumbView.tintColor = color
            lowerThumbView.tintColor = color
        }
    }
    
    @IBInspectable public var lowerValue: Double {
        get {
            return trackLayer.lowerValue
        }
        set(value) {
            trackLayer.lowerValue = upperValue < value ? upperValue : value
            updateLayer()
            sendActionsForControlEvents(.ValueChanged)
        }
    }
    
    @IBInspectable public var upperValue: Double {
        get {
            return trackLayer.upperValue
        }
        set(value) {
            trackLayer.upperValue = value < lowerValue ? lowerValue : value
            updateLayer()
            sendActionsForControlEvents(.ValueChanged)
        }
    }
    
    @IBInspectable public var lowerThumbImage: UIImage? {
        didSet{
            lowerThumbView.image = lowerThumbImage
            lowerThumbView.sizeToFit()
            updateLayer()
        }
    }
    @IBInspectable public var upperThumbImage: UIImage? {
        didSet{
            upperThumbView.image = upperThumbImage
            upperThumbView.sizeToFit()
            updateLayer()
        }
    }
    
    @IBInspectable public var minTouchArea: CGFloat = 20
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        if lowerThumbImage == nil {
            lowerThumbImage = CircleImage.getUIImage((trackHeight*3)/2)
        }
        if upperThumbImage == nil {
            upperThumbImage = CircleImage.getUIImage((trackHeight*3)/2)
        }
        self.updateLayer()
    }
    
    override public func intrinsicContentSize() -> CGSize {
        let imageH = max(CGRectGetHeight(lowerThumbView.bounds), CGRectGetHeight(lowerThumbView.bounds))
        return CGSizeMake(200, max((trackHeight*3)/2, imageH))
    }
    
    func setup(){
        trackLayer.contentsScale = UIScreen.mainScreen().scale
        self.layer.addSublayer(trackLayer)
        self.addSubview(lowerThumbView)
        self.addSubview(upperThumbView)
        self.updateLayer()
    }
    
    func updateLayer() {
        let h = CGRectGetHeight(self.bounds)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        
        let tarckBounds = self.trackBounds
        trackLayer.frame = tarckBounds
        trackLayer.setNeedsDisplay()
        
        lowerThumbView.frame.origin.y = (h - CGRectGetHeight(lowerThumbView.bounds))/2
        upperThumbView.frame.origin.y = (h - CGRectGetHeight(upperThumbView.bounds))/2
        
        lowerThumbView.frame.origin.x = CGFloat(lowerValue) * tarckBounds.width + tarckBounds.origin.x - CGRectGetWidth(lowerThumbView.bounds)/2
        upperThumbView.frame.origin.x = CGFloat(upperValue) * tarckBounds.width + tarckBounds.origin.x - CGRectGetWidth(upperThumbView.bounds)/2
        
        CATransaction.commit()
    }
    
    override public func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        moveTartget = nil
        
        
        for view in self.subviews.reverse() {
            guard view.isKindOfClass(UIImageView) else { continue }
            let w = min(0, CGRectGetWidth(view.frame) - minTouchArea)
            let rect = view.frame.insetBy(dx: w/2, dy: w/2)
            if rect.contains(location) {
                moveTartget = view
                touchX = view.convertPoint(location, fromView: self).x - CGRectGetWidth(view.bounds)/2
                self.bringSubviewToFront(view)
                break
            }
        }
        
        return moveTartget != nil
    }
    
    override public func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        if moveTartget != nil {
            let trackBounds = self.trackBounds
            let width = CGRectGetWidth(trackBounds)
            var location = touch.locationInView(self).x
            location -= trackBounds.origin.x
            location -= touchX
            let x = max(0, min(1, location/width))
            switch moveTartget! {
            case lowerThumbView:
                lowerValue = Double(x)
            case upperThumbView:
                upperValue = Double(x)
            default: break
            }
        }
        return true
    }
    
    override public func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        super.endTrackingWithTouch(touch, withEvent: event)
        moveTartget = nil
        touchX = 0
    }
}