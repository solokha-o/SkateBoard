//
//  MenuLayer.swift
//  SkateBoard
//
//  Created by Oleksandr Solokha on 28.07.2020.
//  Copyright © 2020 Oleksandr Solokha. All rights reserved.
//

import UIKit
import SpriteKit

class MenuLayer: SKSpriteNode {
    //on display info about state of game and resault
    func display(message: String, score: Int?) {
        let messageLable = SKLabelNode(text: message)
        let messageX = -frame.width
        let messageY = frame.height / 2.0
        messageLable.position = CGPoint(x: messageX, y: messageY)
        messageLable.horizontalAlignmentMode = .center
        messageLable.fontName = "Courier-Bold"
        messageLable.fontSize = 48.0
        messageLable.zPosition = 20
        addChild(messageLable)
    }
}
