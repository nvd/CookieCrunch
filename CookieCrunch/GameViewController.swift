import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
    var scene: GameScene!
    var level: Level!

    var movesLeft = 0
    var score = 0
    lazy var backgroundMusic: AVAudioPlayer = {
        let url = NSBundle.mainBundle().URLForResource("Sounds/Mining by Moonlight", withExtension: "mp3")
        let player = (try? AVAudioPlayer(contentsOfURL: url!))!
        player.numberOfLoops = -1
        return player
        }()

    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!

    @IBOutlet weak var gameOverPanel: UIImageView!
    var tapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet weak var shuffleButton: UIButton!

    @IBAction func shuffleButtonPressed(_: AnyObject) {
        shuffle()
        decrementMoves()
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = view as! SKView
        skView.multipleTouchEnabled = false
        shuffleButton.hidden = true

        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill

        level = Level(filename: "Levels/Level_1")
        scene.level = level
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        gameOverPanel.hidden = true

        // Present the scene.
        skView.presentScene(scene)

        backgroundMusic.play()
        beginGame()
    }

    func beginGame() {
        movesLeft = level.maximumMoves
        score = 0
        updateLabels()
        level.resetComboMultiplier()
        scene.animateBeginGame() {
            self.shuffleButton.hidden = false
        }
        shuffle()
    }

    func shuffle() {
        scene.removeAllCookieSprites()
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
        if chains.count == 0 {
            beginNextTurn()
            return
        }

        scene.animateMatchedCookies(chains) {
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabels()
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns) {
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns) {
                    self.handleMatches()
                }
            }
        }
    }

    func beginNextTurn() {
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        view.userInteractionEnabled = true
        decrementMoves()
    }

    func updateLabels() {
        targetLabel.text = String(format: "%ld", level.targetScore)
        movesLabel.text = String(format: "%ld", movesLeft)
        scoreLabel.text = String(format: "%ld", score)
    }

    func decrementMoves() {
        --movesLeft
        updateLabels()
        if score >= level.targetScore {
            gameOverPanel.image = UIImage(named: "LevelComplete")
            showGameOver()
        } else if movesLeft == 0 {
            gameOverPanel.image = UIImage(named: "GameOver")
            showGameOver()
        }
    }

    func showGameOver() {
        gameOverPanel.hidden = false
        scene.userInteractionEnabled = false
        shuffleButton.hidden = true

        scene.animateGameOver() {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideGameOver")
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }

    func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil

        gameOverPanel.hidden = true
        scene.userInteractionEnabled = true

        beginGame()
    }
}