//
//  Skater.swift
//  SkateBoard
//
//  Created by Oleksandr Solokha on 30.06.2020.
//  Copyright © 2020 Oleksandr Solokha. All rights reserved.
//

import SpriteKit

class Skater: SKSpriteNode {
    
    var velocity = CGPoint.zero
    var minimumY : CGFloat = 0.0
    var jumpSpeed : CGFloat = 20.0
    var isOnGroud = true
    //configure physics texture of skater
    func setupPhysicsBody() {
        if let skaterTexture = texture {
            physicsBody = SKPhysicsBody(texture: skaterTexture, size: size)
            physicsBody?.isDynamic = true
            physicsBody?.density = 6.0
            physicsBody?.allowsRotation = true
            physicsBody?.angularDamping = 1.0
            physicsBody?.categoryBitMask = PhysicsCategory.skater
            physicsBody?.collisionBitMask = PhysicsCategory.brick
            physicsBody?.contactTestBitMask = PhysicsCategory.brick | PhysicsCategory.gem
        }
    }
}
