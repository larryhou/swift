//
//  PolygonGeometry.swift
//  MeshPathFinder
//
//  Created by larryhou on 7/9/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit

class UIPolygon: SKShapeNode {
    func randomPolygonVertexAngles(_ sideCount: Int, equilateral: Bool = false, repeatCount: Int = 1)->(vertex: [CGFloat], area: CGFloat) {
        let repeatCount = equilateral ? 1 : repeatCount
        let total = CGFloat.pi * 2, delta = total / CGFloat(sideCount)

        var maxArea: CGFloat = 0.0, vertex: [CGFloat] = Array(repeating: 0.0, count: sideCount)

        for _ in 0..<repeatCount {
            var parts: [CGFloat] = [], divider: CGFloat = 0.0
            for _ in 0..<sideCount {
                let num = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 0xFF))
                parts.append(num)
                divider += num
            }

            var area: CGFloat = 0.0, sum: CGFloat = 0.0
            for i in 1...sideCount {
                let angle: CGFloat
                if i == sideCount {
                    angle = total - sum
                } else {
                    if !equilateral {
                        angle = total * parts[i - 1] / divider
                    } else {
                        angle = delta
                    }
                }

                area += sin(angle / 2) * cos(angle / 2)
                sum += angle

                parts[i - 1] = sum
            }

            if area > maxArea {
                vertex = parts
                maxArea = area
            }
        }

        return (vertex, maxArea)
    }

}
