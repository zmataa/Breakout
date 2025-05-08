//
//  GameScene.swift
//  Breakout
//
//  Created by Zane Matarieh on 3/17/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    var ball = SKShapeNode()
    var paddle = SKSpriteNode()
    var bricks = [SKSpriteNode]()
    var removedBricks = 0
    var loseZone = SKSpriteNode()
    var playLabel = SKLabelNode()
    var livesLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
    var playingGame = false
    var score = 0
    var lives = 3

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        createBackground()
        makeLabels()
        resetGame()
    }

    func createBackground() {
        let stars = SKTexture(imageNamed: "Stars")
        for i in 0...1 {
            let starsBackground = SKSpriteNode(texture: stars)
            starsBackground.zPosition = -1
            starsBackground.position = CGPoint(x: 0, y: starsBackground.size.height * CGFloat(i))
            addChild(starsBackground)
            let moveDown = SKAction.moveBy(x: 0, y: -starsBackground.size.height, duration: 20)
            let moveReset = SKAction.moveBy(x: 0, y: starsBackground.size.height, duration: 0)
            let moveLoop = SKAction.sequence([moveDown, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            starsBackground.run(moveForever)
        }
    }

    func makeBrick(x: Int, y: Int, color: UIColor) {
        let brick = SKSpriteNode(color: color, size: CGSize(width: 50, height: 20))
        brick.position = CGPoint(x: x, y: y)
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
        brick.physicsBody?.isDynamic = false
        addChild(brick)
        bricks.append(brick)
    }

    func makeBricks() {
        for brick in bricks {
            brick.removeFromParent()
        }
        bricks.removeAll()
        removedBricks = 0

        let count = Int(frame.width) / 55
        let xOffset = (Int(frame.width) - (count * 55)) / 2 + Int(frame.minX) + 25
        let colors: [UIColor] = [.blue, .orange, .green]
        for r in 0..<3 {
            let y = Int(frame.maxY) - 65 - (r * 25)
            for i in 0..<count {
                let x = i * 55 + xOffset
                makeBrick(x: x, y: y, color: colors[r])
            }
        }
    }

    func makePaddle() {
        paddle.removeFromParent()
        paddle = SKSpriteNode(color: .white, size: CGSize(width: frame.width / 4, height: 20))
        paddle.position = CGPoint(x: frame.midX, y: frame.minY + 125)
        paddle.name = "paddle"
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.isDynamic = false
        addChild(paddle)
    }

    func makeBall() {
        ball.removeFromParent()
        ball = SKShapeNode(circleOfRadius: 10)
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        ball.strokeColor = .black
        ball.fillColor = .yellow
        ball.name = "ball"
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        ball.physicsBody?.isDynamic = false
        ball.physicsBody?.usesPreciseCollisionDetection = true
        ball.physicsBody?.friction = 0
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.restitution = 1
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.contactTestBitMask = ball.physicsBody!.collisionBitMask
        addChild(ball)
    }

    func makeLoseZone() {
        loseZone.removeFromParent()
        loseZone = SKSpriteNode(color: .red, size: CGSize(width: frame.width, height: 50))
        loseZone.position = CGPoint(x: frame.midX, y: frame.minY + 25)
        loseZone.name = "loseZone"
        loseZone.physicsBody = SKPhysicsBody(rectangleOf: loseZone.size)
        loseZone.physicsBody?.isDynamic = false
        addChild(loseZone)
    }

    func resetGame() {
        makeBall()
        makePaddle()
        makeBricks()
        makeLoseZone()
        updateLabels()
    }

    func kickBall() {
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.applyImpulse(CGVector(dx: Int.random(in: -5...5), dy: 5))
    }

    func updateLabels() {
        scoreLabel.text = "Score: \(score)"
        livesLabel.text = "Lives: \(lives)"
    }

    func flashRed() {
        let flash = SKSpriteNode(color: .red, size: self.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.zPosition = 100
        flash.alpha = 0.75
        addChild(flash)

        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        flash.run(SKAction.sequence([fadeOut, remove]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if playingGame {
                paddle.position.x = location.x
            } else {
                for node in nodes(at: location) {
                    if node.name == "playLabel" {
                        // remove game over screen
                        childNode(withName: "playLabel")?.removeFromParent()
                        childNode(withName: "gameOverBox")?.removeFromParent()
                        childNode(withName: "resultLabel")?.removeFromParent()

                        lives = 3
                        score = 0
                        updateLabels()
                        resetGame()
                        kickBall()
                        playingGame = true
                    }

                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if playingGame {
                paddle.position.x = location.x
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        for brick in bricks {
            if contact.bodyA.node == brick || contact.bodyB.node == brick {
                score += 1
                ball.physicsBody!.velocity.dx *= 1.02
                ball.physicsBody!.velocity.dy *= 1.02
                updateLabels()
                if brick.color == .blue {
                    brick.color = .orange
                } else if brick.color == .orange {
                    brick.color = .green
                } else {
                    brick.removeFromParent()
                    removedBricks += 1
                    if removedBricks == bricks.count {
                        gameOver(winner: true)
                    }
                }
            }
        }

        if contact.bodyA.node?.name == "loseZone" || contact.bodyB.node?.name == "loseZone" {
            if !playingGame { return }

            ball.physicsBody?.isDynamic = false
            ball.removeFromParent()

            flashRed()
            lives -= 1
            updateLabels()

            if lives > 0 {
                score = 0
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run {
                        self.resetGame()
                        self.kickBall()
                    }
                ]))
            } else {
                gameOver(winner: false)
            }
        }
    }

    func makeLabels() {
        playLabel.fontSize = 24
        playLabel.text = "Tap to start"
        playLabel.fontName = "Arial"
        playLabel.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        playLabel.name = "playLabel"
        addChild(playLabel)

        scoreLabel.fontSize = 18
        scoreLabel.fontColor = .white
        scoreLabel.fontName = "Arial"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: frame.minX + 20, y: frame.minY + 20)
        addChild(scoreLabel)

        livesLabel.fontSize = 18
        livesLabel.fontColor = .white
        livesLabel.fontName = "Arial"
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.position = CGPoint(x: frame.maxX - 20, y: frame.minY + 20)
        addChild(livesLabel)
    }
    func gameOver(winner: Bool) {
        playingGame = false
        
        //box color depends on win or loser
        let colorBox = SKSpriteNode(color: winner ? .green : .red, size: CGSize(width: 250, height: 150))
        colorBox.position = CGPoint(x: frame.midX, y: frame.midY)
        colorBox.zPosition = 100
        colorBox.name = "gameOverBox"
        addChild(colorBox)

        // label according to wiun or lose
        let resultLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        resultLabel.text = winner ? "You Win!" : "You Lose"
        resultLabel.fontSize = 28
        resultLabel.fontColor = .white
        resultLabel.position = CGPoint(x: frame.midX, y: frame.midY + 20)
        resultLabel.zPosition = 101
        resultLabel.name = "resultLabel"
        addChild(resultLabel)

        // play again button
        let playAgain = SKLabelNode(fontNamed: "Arial-BoldMT")
        playAgain.text = "Play Again"
        playAgain.fontSize = 20
        playAgain.fontColor = .white
        playAgain.position = CGPoint(x: frame.midX, y: frame.midY - 30)
        playAgain.zPosition = 101
        playAgain.name = "playLabel"
        addChild(playAgain)
    }


//    func gameOver(winner: Bool) {
//        playingGame = false
//        playLabel.alpha = 1
//        playLabel.text = winner ? "You win! Tap to play again" : "You lose! Tap to play again"
//    }

    override func update(_ currentTime: TimeInterval) {
        if abs(ball.physicsBody!.velocity.dx) < 100 {
            ball.physicsBody?.applyImpulse(CGVector(dx: Int.random(in: -3...3), dy: 0))
        }
        if abs(ball.physicsBody!.velocity.dy) < 100 {
            ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: Int.random(in: -3...3)))
        }
    }
}
