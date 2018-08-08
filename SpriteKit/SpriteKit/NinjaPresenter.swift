//
//  NinjaPresenter.swift
//  SpriteKit
//
//  Created by larryhou on 25/5/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class NinjaPresenter: SKSpriteNode {
    var atlas: SKTextureAtlas!
    var actionInfos: [NinjaActionInfo]!
    var data: NinjaActionInfo!

    var frameIndex: Int = 0
    var frameCount: Int = 0

    var layers: [SKSpriteNode]!

    convenience init(atlas: SKTextureAtlas, actionInfos: [NinjaActionInfo]) {
        self.init(color: UIColor.clearColor(), size: CGSize(width: 1, height: 1))
        self.actionInfos = actionInfos
        self.atlas = atlas
    }

    func playNextAction() {
        let index = (data.index + 1) % actionInfos.count
        play(actionInfos[index].name)
    }

    func play(name: String) -> Bool {
        removeAllChildren()

        data = nil
        for i in 0 ..< actionInfos.count {
            if name == actionInfos[i].name {
                data = actionInfos[i]
                break
            }
        }

        if data == nil {
            return false
        }

        layers = []
        for i in 0..<data.layers.count {
            var list: [SKAction] = []
            var sprite = SKSpriteNode()
            addChild(sprite)

            var index: Int = 0
            let layerInfo = data.layers[i]
            for j in 0 ..< layerInfo.length {
                if j >= layerInfo.frames[index].position {
                    index++
                }

                let frame = layerInfo.frames[index]
                if frame.texture != "" {
                    list.append(SKAction.setTexture(atlas.textureNamed(frame.texture), resize: true))
                    list.append(SKAction.runBlock({
                        sprite.position.x = CGFloat(frame.x)
                        sprite.position.y = CGFloat(frame.y)
                    }))
                } else {
                    list.append(SKAction.waitForDuration(1/30))
                }
            }

            list.append(SKAction.removeFromParent())
            sprite.runAction(SKAction.sequence(list))
        }

        return true
    }
}
