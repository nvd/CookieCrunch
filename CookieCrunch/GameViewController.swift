import UIKit
import SpriteKit

class GameViewController: UIViewController {
    var scene: GameScene!
    var level: Level!

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = view as! SKView
        skView.multipleTouchEnabled = false

        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill

        level = Level(filename: "Levels/Level_3")
        scene.level = level
        scene.addTiles()
        scene.swipeHandler = handleSwipe

        // Present the scene.
        skView.presentScene(scene)

        beginGame()
    }

    func beginGame() {
        shuffle()
    }

    func shuffle() {
        let newCookies = level.shuffle()
        scene.addSpritesForCookies(newCookies)
    }

    func handleSwipe(swap: Swap) {
        view.userInteractionEnabled = false

        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            scene.animateSwap(swap, completion: handleMatches)
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.userInteractionEnabled = true
            }
        }
    }

    func handleMatches() {
        let chains = level.removeMatches()
        scene.animateMatchedCookies(chains) {
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns) {
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns) {
                    self.view.userInteractionEnabled = true
                }
            }
        }
    }
}