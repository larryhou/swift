//
//  CameraPreviewView.swift
//  MRCodes
//
//  Created by larryhou on 13/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - self.x
        let dy = point.y - self.y
        return sqrt(dx * dx + dy * dy)
    }
}

class CameraPreviewView: UIView {
    override static var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var session: AVCaptureSession! {
        get {
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }

        set {
            (self.layer as! AVCaptureVideoPreviewLayer).session = newValue
        }
    }
}

class CameraMetadataView: UIView {
    var mrcObjects: [AVMetadataMachineReadableCodeObject]!

    func setMetadataObjects(_ mrcObjects: [AVMetadataMachineReadableCodeObject]) {
        self.mrcObjects = unique(of: mrcObjects)
        setNeedsDisplay()
    }

    func getRelatedArea(of mrcObject: AVMetadataMachineReadableCodeObject) -> CGPath {
        var points: [CGPoint] = mrcObject.corners

        let path = CGMutablePath()
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }

        path.addLine(to: points[0])

        return path
    }

    func getRelatedCorners(of mrcObject: AVMetadataMachineReadableCodeObject) -> CGPath {
        let points = mrcObject.corners
        let length: CGFloat = 10

        let path = CGMutablePath()
        for n in 0..<points.count {
            let pf = points[n]
            let pt = n < points.count - 1 ? points[n + 1] : points[0]

            let angle = atan2(pt.y - pf.y, pt.x - pf.x)
            let dx = length * cos(angle)
            let dy = length * sin(angle)

            path.move(to: pf)
            path.addLine(to: CGPoint(x: pf.x + dx, y: pf.y + dy))

            path.move(to: pt)
            path.addLine(to: CGPoint(x: pt.x - dx, y: pt.y - dy))
        }
        return path
    }

    func unique(of objects: [AVMetadataMachineReadableCodeObject]) -> [AVMetadataMachineReadableCodeObject] {
        guard objects.count >= 2 else {return objects}

        var list = objects.map({character(of: $0)})
        list.sort(by: {$0.offset < $1.offset})

        var result: [AVMetadataMachineReadableCodeObject] = []

        var refer = list[0]
        result.append(refer.object)

        for n in 1..<list.count {
            let current = list[n]
            if current.center.distance(to: refer.center) < refer.radius {
                if current.radius > refer.radius {
                    result[result.count - 1] = current.object
                } else {continue}
            } else {
                result.append(current.object)
            }
            refer = current
        }

        return result
    }

    func character(of mrcObject: AVMetadataMachineReadableCodeObject)->(center: CGPoint, radius: CGFloat, object: AVMetadataMachineReadableCodeObject, offset: CGFloat) {
        var center = CGPoint()
        for corner in mrcObject.corners {
            center.x += corner.x
            center.y += corner.y
        }
        center.x /= 4
        center.y /= 4

        let frameCenter = CGPoint(x: frame.origin.x + frame.width / 2, y: frame.origin.y + frame.height / 2)

        let offset = frameCenter.distance(to: center)

        let distances = mrcObject.corners.map { $0.distance(to: center) }

        let radius = distances.reduce(0, {$0 + $1}) / CGFloat(distances.count)
        return (center, radius, mrcObject, offset)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {return}

        if mrcObjects != nil && mrcObjects.count > 0 {
            context.saveGState()
            context.setLineJoin(.miter)
            context.setLineCap(.square)

            for n in 0..<mrcObjects.count {
                let mrc = mrcObjects[n]
                let color: UIColor = n == 0 ? .green : .yellow

                context.setStrokeColor(color.cgColor)

                context.setLineWidth(2.0)
                context.addPath(getRelatedCorners(of: mrc))
                context.strokePath()

                let area = getRelatedArea(of: mrc)

                context.setLineWidth(0.5)
                context.addPath(area)
                context.strokePath()

                context.addPath(area)
                context.setFillColor(color.withAlphaComponent(0.1).cgColor)
                context.fillPath()

                if n == 0 {
                    if let stringValue = mrc.stringValue {
                        UIPasteboard.general.string = stringValue
                    }
                }
            }

            context.restoreGState()
        }
    }
}
