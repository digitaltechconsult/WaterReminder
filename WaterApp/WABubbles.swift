//
//  WABubbles.swift
//  WaterApp
//
//  Created by Bogdan Coticopol on 07/03/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

/**
 `SKScene` subclass to display the bubbles animation
 */
class WABubbles: SKScene {
    
    /// Flag to know when to render in `addBubbles:`. If true, then the rendering is not called.
    /// The value of this flag is changed automatically inside the animation body
    var stillRendering: Bool = false
    
    /**
     Creates an `SKEmitterNode` with the bubble animation
     - parameters:
     - posX: the `x` location
     - posY: the `y` location
     - returns: `SKEmitterNode` containing the bubble animation
     */
    func sparklingWithPosX(posX: CGFloat, posY: CGFloat) -> SKEmitterNode {
        let bubbles = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("MyParticle", ofType: "sks")!) as! SKEmitterNode
        bubbles.position = CGPointMake(posX, posY)
        bubbles.name = "bubbles"
        bubbles.targetNode = self.scene
        bubbles.numParticlesToEmit = 30
        bubbles.zPosition = 2.0
        return bubbles
    }
    
    
    /**
     Add bubbles animation to the scene and remove it after a specified time
     - parameters:
     - point: the point where the animation will be displayed
     */
    func addBubbles(point: CGPoint) {
        if !self.stillRendering {
            let bubbles = self.sparklingWithPosX(point.x, posY: 0)
            let addAction = SKAction.runBlock {
                self.stillRendering = true
                self.addChild(bubbles)
            }
            let waitAction = SKAction.waitForDuration(2.5)
            let removeAction = SKAction.runBlock {
                bubbles.removeFromParent()
                self.stillRendering = false
            }
            let sequence = SKAction.sequence([addAction, waitAction, removeAction])
            self.runAction(sequence)
        }
    }
    
}
