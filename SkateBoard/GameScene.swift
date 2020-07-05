//
//  GameScene.swift
//  SkateBoard
//
//  Created by Oleksandr Solokha on 27.06.2020.
//  Copyright © 2020 Oleksandr Solokha. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    //create instance of Skater
    let skater = Skater(imageNamed: "skater")
    //create array bricks
    var bricks = [SKSpriteNode]()
    //brick size on road
    var brickSize = CGSize.zero
    // bricks speed
    var scrollSpeed : CGFloat = 5.0
    // create property for time interval update game
    var lastUpdateTime : TimeInterval?
    // create gravity
    let gravitySpeed : CGFloat = 1.5
    
    
    
    override func didMove(to view: SKView) {
        anchorPoint = CGPoint.zero
        //call setup and configure function
        setupBackground()
        resetSkater()
        // add tapGesture to scene
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GameScene.handleTap(tapGesture:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func update(_ currentTime: TimeInterval) {
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
    }
    //configure tapGesture
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        if skater.isOnGroud {
            skater.velocity = CGPoint(x: 0.0, y: skater.jumpSpeed)
            skater.isOnGroud = false
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
        addChild(skater)
    }
    //configure brick
    func spawnBrick (atPosition position: CGPoint) -> SKSpriteNode {
        let brick = SKSpriteNode(imageNamed: "sidewalk")
        brick.position = position
        brick.zPosition = 8
        addChild(brick)
        brickSize = brick.size
        bricks.append(brick)
        return brick
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
        // create new brick
        while farthestRightBrickX < frame.width {
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = brickSize.height / 2.0
            //create hole in brick
            let rundomNumber = arc4random_uniform(99)
            if rundomNumber < 5 {
                let gap = 20.0 * scrollSpeed
                brickX += gap
            }
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
        }
    }
    //configure update skater on screen
    func updateSkater() {
        if !skater.isOnGroud {
            let velocityY = skater.velocity.y - gravitySpeed
            skater.velocity = CGPoint(x: skater.velocity.x, y: velocityY)
            let newSkaterY = skater.position.y + skater.velocity.y
            skater.position = CGPoint(x: skater.position.x, y: newSkaterY)
        }
    }
    
}

