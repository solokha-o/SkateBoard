//
//  GameScene.swift
//  SkateBoard
//
//  Created by Oleksandr Solokha on 27.06.2020.
//  Copyright © 2020 Oleksandr Solokha. All rights reserved.
//

import SpriteKit
import GameplayKit
//get physics category to objects of game
struct PhysicsCategory {
    static let skater : UInt32 = 0x1 << 0
    static let brick : UInt32 = 0x1 << 1
    static let gem : UInt32 = 0x1 << 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //create enum of brick level
    enum BrickLevel: CGFloat {
        case low = 0.0
        case high = 100.0
    }
    
    //create instance of Skater
    let skater = Skater(imageNamed: "skater")
    //create array bricks
    var bricks = [SKSpriteNode]()
    //brick size on road
    var brickSize = CGSize.zero
    // bricks speed
    var scrollSpeed : CGFloat = 5.0
    //create starting speed
    let startingScrollSpeed : CGFloat = 5.0
    // create property for time interval update game
    var lastUpdateTime : TimeInterval?
    // create gravity
    let gravitySpeed : CGFloat = 1.5
    // create instance of brick level
    var brickLevel = BrickLevel.low
    // create array of gems
    var gems = [SKSpriteNode]()
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        // add contact delegate
        physicsWorld.contactDelegate = self
        anchorPoint = CGPoint.zero
        //call setup and configure function
        setupBackground()
        skater.setupPhysicsBody()
        addChild(skater)
        // add tapGesture to scene
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GameScene.handleTap(tapGesture:)))
        view.addGestureRecognizer(tapGesture)
        startGame()
    }
   
    override func update(_ currentTime: TimeInterval) {
        //boost speed
        scrollSpeed += 0.01
        // configure time update animation
        var elapsedTime : TimeInterval = 0.0
        if let lastTimeStamp = lastUpdateTime {
            elapsedTime = currentTime - lastTimeStamp
        }
        lastUpdateTime = currentTime
        let expectedElapsedTime : TimeInterval = 1.0 / 60.0
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
        let currentScrollAmount = scrollSpeed * scrollAdjustment
        updateBricks(withScrollAmount: currentScrollAmount)
        updateSkater()
    }
    //configure tapGesture
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        if skater.isOnGroud {
            skater.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
        }
    }
    // MARK:- SKPhysicsContactDelegate Methods
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            skater.isOnGroud = true
        }
    }
    //setup background image
    func setupBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
    }
    //setup skater on scene
    func resetSkater() {
        let skaterX = frame.midX / 2.0
        let skaterY = skater.frame.height / 2.0 + 64.0
        skater.position = CGPoint(x: skaterX, y: skaterY)
        skater.zPosition = 10.0
        skater.minimumY = skaterY
        skater.zPosition = 0.0
        skater.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        skater.physicsBody?.angularVelocity = 0.0
    }
    //configure start game
    func startGame() {
        resetSkater()
        scrollSpeed = startingScrollSpeed
        brickLevel = .low
        lastUpdateTime = nil
        for brick in bricks {
            brick.removeFromParent()
        }
        bricks.removeAll(keepingCapacity: true)
    }
    // configure game over
    func gameOver() {
        startGame()
    }
    //configure brick
    func spawnBrick (atPosition position: CGPoint) -> SKSpriteNode {
        let brick = SKSpriteNode(imageNamed: "sidewalk")
        brick.position = position
        brick.zPosition = 8
        addChild(brick)
        brickSize = brick.size
        bricks.append(brick)
        let center = brick.centerRect.origin
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: center)
        brick.physicsBody?.affectedByGravity = false
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = 0
        return brick
    }
    //configure gem
    func spawnGem(atPosition position: CGPoint) {
        let gem = SKSpriteNode(imageNamed: "gem")
        gem.position = position
        gem.zPosition = 9
        addChild(gem)
        gem.physicsBody = SKPhysicsBody(rectangleOf: gem.size, center: gem.centerRect.origin)
        gem.physicsBody?.categoryBitMask = PhysicsCategory.gem
        gem.physicsBody?.affectedByGravity = false
        gems.append(gem)
    }
    //configure building road from bricks
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
        // position of first brick
        var farthestRightBrickX: CGFloat = 0.0
        //update position of brick if position is not on screen remove brick else update new position for x
        for brick in bricks {
            let newX = brick.position.x - currentScrollAmount
            if newX < -brickSize.width {
                brick.removeFromParent()
                if let brickIndex = bricks.firstIndex(of: brick) {
                    bricks.remove(at: brickIndex)
                }
            } else {
                brick.position = CGPoint(x: newX, y: brick.position.y)
                if brick.position.x > farthestRightBrickX {
                    farthestRightBrickX = brick.position.x
                }
            }
        }
        // create new brick with bricl level
        while farthestRightBrickX < frame.width {
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = brickSize.height / 2.0 + brickLevel.rawValue
            //create hole in brick
            let rundomNumber = arc4random_uniform(99)
            if rundomNumber < 5 {
                let gap = 20.0 * scrollSpeed
                brickX += gap
            }
            else if rundomNumber < 10 {
                if brickLevel == .high {
                    brickLevel = .low
                }
                else if brickLevel == .low {
                    brickLevel = .high
                }
            }
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
        }
    }
    //configure update skater on screen - jump and down
    func updateSkater() {
        if let velocityY = skater.physicsBody?.velocity.dy {
            if velocityY < -100.0 || velocityY > 100.0 {
                skater.isOnGroud = false
            }
        }
        let isOffScreen = skater.position.y < 0.0 || skater.position.x < 0.0
        let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0))
        let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation
        if isOffScreen || isTippedOver {
            gameOver()
        }
    }
}

