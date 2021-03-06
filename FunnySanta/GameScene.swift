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
    static let santa : UInt32 = 0x1 << 0
    static let brick : UInt32 = 0x1 << 1
    static let gem : UInt32 = 0x1 << 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //create enum of brick level
    enum BrickLevel: CGFloat {
        case low = 0.0
        case high = 100.0
    }
    //create enum state of game
    enum StateGame {
        case notRunning
        case running
    }
    //create instance of Santa
    var santa = Santa()
    //create SKTexture array for animate santa sprite
    var santaWalkingFrames : [SKTexture] = []
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
    //create instance score and best score
    var score = 0
    var highScore = 0
    var lastScoreUpdateTime : TimeInterval = 0.0
    //create state of game
    var stateGame = StateGame.notRunning
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        // add contact delegate
        physicsWorld.contactDelegate = self
        anchorPoint = CGPoint.zero
        //call setup and configure function
        setupBackground()
        setupLabels()
        buildSanta()
        santaAnimate()
        // add tapGesture to scene
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GameScene.handleTap(tapGesture:)))
        view.addGestureRecognizer(tapGesture)
        //display start game menu
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint(x: 0, y: 0)
        menuLayer.position = CGPoint(x: 0, y: 0)
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Press to Start game", score: nil)
        addChild(menuLayer)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // break game
        if stateGame != .running {
            return
        }
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
        // call function update node by currentScrollAmount
        updateBricks(withScrollAmount: currentScrollAmount)
        updateSanta()
        updateGem(withScrollAmount: currentScrollAmount)
        //call function update node by currentTime
        updateScore(withCurrentTime: currentTime)
    }
    //configure tapGesture
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        if stateGame == .running {
            if santa.isOnGroud {
                santa.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
                // sound when santa jump
                run(SKAction.playSoundFileNamed("jump.wav", waitForCompletion: false))
            }
        } else {
            if let menuLayer: SKSpriteNode = childNode(withName: "menuLayer") as? SKSpriteNode {
                menuLayer.removeFromParent()
                startGame()
            }
        }
    }
    // MARK:- SKPhysicsContactDelegate Methods
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == PhysicsCategory.santa && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            if let velocityY = santa.physicsBody?.velocity.dy {
                if !santa.isOnGroud && velocityY < 100.0 {
                    santa.createSparks()
                }
            }
            santa.isOnGroud = true
        }
        else if contact.bodyA.categoryBitMask == PhysicsCategory.santa && contact.bodyB.categoryBitMask == PhysicsCategory.gem {
            if let gem = contact.bodyB.node as? SKSpriteNode {
                removeGem(gem)
                score += 50
                //sound when take gem
                run(SKAction.playSoundFileNamed("gem.wav", waitForCompletion: false))
                updateScoreTextLable()
            }
        }
    }
    // build frame santa on scene
    func buildSanta() {
        let santaAnimatedAtlas = SKTextureAtlas(named: "Santa")
        var walkFrames: [SKTexture] = []
        let numImages = santaAnimatedAtlas.textureNames.count
        for i in 1...numImages {
            let imageName = "Santa\(i)"
            walkFrames.append(SKTexture(imageNamed: imageName))
        }
        santaWalkingFrames = walkFrames
        let firstTextureFrame = santaWalkingFrames[0]
        santa = Santa(texture: firstTextureFrame)
        santa.setupPhysicsBody()
        addChild(santa)
    }
    //animate walking santa
    func santaAnimate() {
        let santaWalkAnimate = SKAction.animate(with: santaWalkingFrames, timePerFrame: 0.1)
        santa.run(SKAction.repeatForever(santaWalkAnimate))
    }
    //setup background image
    func setupBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
    }
    //setup santa on scene
    func resetSanta() {
        let santaX = frame.midX / 2.0
        let santaY = santa.frame.height / 2.0 + 64.0
        santa.position = CGPoint(x: santaX, y: santaY)
        santa.zPosition = 10.0
        santa.minimumY = santaY
        santa.zPosition = 0.0
        santa.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        santa.physicsBody?.angularVelocity = 0.0
    }
    //configure labels with points gamer and best resault
    func setupLabels() {
        let scoreTextLabel : SKLabelNode = SKLabelNode(text: "Points")
        scoreTextLabel.position = CGPoint(x: 14.0, y: frame.size.height - 20.0)
        scoreTextLabel.horizontalAlignmentMode = .left
        scoreTextLabel.fontName = "Courier-Bold"
        scoreTextLabel.fontSize = 18.0
        scoreTextLabel.zPosition = 20
        addChild(scoreTextLabel)
        let scoreLabel: SKLabelNode = SKLabelNode(text: "0")
        scoreLabel.position = CGPoint(x: 14.0, y: frame.size.height - 40.0)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontName = "Courier-Bold"
        scoreLabel.fontSize = 20.0
        scoreLabel.name = "scoreLabel"
        scoreLabel.zPosition = 20
        addChild(scoreLabel)
        let highScoreTextLabel: SKLabelNode = SKLabelNode(text: "Best resault")
        highScoreTextLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 20.0)
        highScoreTextLabel.horizontalAlignmentMode = .right
        highScoreTextLabel.fontName = "Courier-Bold"; highScoreTextLabel.fontSize = 18.0
        highScoreTextLabel.zPosition = 20
        addChild(highScoreTextLabel)
        let highScoreLabel: SKLabelNode = SKLabelNode(text: "0")
        highScoreLabel.position = CGPoint(x: frame.size.width - 14.0, y: frame.size.height - 40.0)
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.fontName = "Courier-Bold"
        highScoreLabel.fontSize = 20.0
        highScoreLabel.name = "highScoreLabel"
        highScoreLabel.zPosition = 20
        addChild(highScoreLabel)
    }
    //configure update score text in labels
    func updateScoreTextLable() {
        if let scoreLable = childNode(withName: "scoreLabel") as? SKLabelNode {
            scoreLable.text = String(format: "%04d", score)
        }
    }
    //configure update high score text in labels
    func updateHighScoreTextLabel() {
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            highScoreLabel.text = String(format: "%04d", highScore)
        }
    }
    //configure start game
    func startGame() {
        stateGame = .running
        resetSanta()
        score = 0
        scrollSpeed = startingScrollSpeed
        brickLevel = .low
        lastUpdateTime = nil
        for brick in bricks {
            brick.removeFromParent()
        }
        bricks.removeAll(keepingCapacity: true)
        for gem in gems {
            removeGem(gem)
        }
    }
    // configure game over
    func gameOver() {
        if score > highScore {
            highScore = score
            updateHighScoreTextLabel()
        }
        //display game over menu
        let menuBackgroundColor = UIColor.black.withAlphaComponent(0.4)
        let menuLayer = MenuLayer(color: menuBackgroundColor, size: frame.size)
        menuLayer.anchorPoint = CGPoint(x: 0, y: 0)
        menuLayer.position = CGPoint(x: 0, y: 0)
        menuLayer.zPosition = 30
        menuLayer.name = "menuLayer"
        menuLayer.display(message: "Game over!", score: score)
        addChild(menuLayer)
        stateGame = .notRunning
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
    //configure remove gem
    func removeGem (_ gem: SKSpriteNode) {
        gem.removeFromParent()
        if let gemIndex = gems.firstIndex(of: gem) {
            gems.remove(at: gemIndex)
        }
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
        // create new brick with brick level
        while farthestRightBrickX < frame.width {
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = brickSize.height / 2.0 + brickLevel.rawValue
            //create hole in brick
            let rundomNumber = arc4random_uniform(99)
            if rundomNumber < 2 && score > 10 {
                let gap = 20.0 * scrollSpeed
                brickX += gap
                // create gem where gap
                let randomGemYamount = CGFloat(arc4random_uniform(150))
                let newGemY = brickY + santa.size.height + randomGemYamount
                let newGemX = brickX - gap / 2.0
                spawnGem(atPosition: CGPoint(x: newGemX, y: newGemY))
            }
            else if rundomNumber < 4 && score > 20 {
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
    // configure update gems in scroll speed
    func updateGem(withScrollAmount currentScrollAmount: CGFloat) {
        for gem in gems {
            let gemX = gem.position.x - currentScrollAmount
            gem.position = CGPoint(x: gemX, y: gem.position.y)
            if gem.position.x < 0.0 {
                removeGem(gem)
            }
        }
    }
    // configure update score
    func updateScore(withCurrentTime currentTime: TimeInterval) {
        let elapsedTime = currentTime - lastScoreUpdateTime
        if elapsedTime > 1.0 {
            score += Int(scrollSpeed)
            lastScoreUpdateTime = currentTime
            updateScoreTextLable()
        }
    }
    //configure update santa on screen - jump and down
    func updateSanta() {
        if let velocityY = santa.physicsBody?.velocity.dy {
            if velocityY < -100.0 || velocityY > 100.0 {
                santa.isOnGroud = false
            }
        }
        let isOffScreen = santa.position.y < 0.0 || santa.position.x < 0.0
        let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0))
        let isTippedOver = santa.zRotation > maxRotation || santa.zRotation < -maxRotation
        if isOffScreen || isTippedOver {
            gameOver()
        }
    }
}

