//
//  EmojizeGameManager.swift
//  Book_Sources
//
//  Created by Julian Schiavo on 22/3/2019.
//

import AudioToolbox
import CoreImage
import UIKit

public enum Status {
    case normal(String)
    
    case success(String)
    case error(String)
    case warning(String)
    
    case none
    
    var attributedString: NSAttributedString {
        switch self {
        case .normal(let text):
            return NSAttributedString(string: text)
        case .success(let text):
            return NSAttributedString(string: text, attributes: [.foregroundColor: UIColor.green])
        case .error(let text):
            return NSAttributedString(string: text, attributes: [.foregroundColor: UIColor.red, .font: UIFont.systemFont(ofSize: 35, weight: .heavy)])
        case .warning(let text):
            return NSAttributedString(string: text, attributes: [.foregroundColor: UIColor.yellow])
        default:
            return NSAttributedString(string: "")
        }
    }
}

@available(iOS 11.0, *)
public class EmojizeGameManager {
    var isPlaying = false
    var isIntro = false
    var isAnimating = false
    var isErrorRecoverable = true
    
    var timer: Timer?
    var timeLeft = 5 {
        didSet {
            viewController.countdown(to: timeLeft)
        }
    }
    
    var score = 0 {
        didSet {
            viewController.setScore(String(score))
        }
    }
    var emojiTypes = Emoji.Category.allCases
    var emojiMatches = 0
    var currentEmoji = Emoji.😀 {
        didSet {
            viewController.emojiLabel?.setEmoji(currentEmoji, completion: emojiDidSet)
        }
    }
    
    public var viewController: EmojizeViewController!
    
    /// Creates a new `EmojizeGameManager` with the specified parameters
    public init(emojiTypes: [Emoji.Category] = Emoji.Category.allCases, isIntro: Bool = false) {
        self.isIntro = isIntro
        self.emojiTypes = emojiTypes
        self.viewController = EmojizeViewController(manager: self)
        setRandomEmoji()
    }
    
    /// Detects faces on the CIImage and processes the faces to check if the emoji matches
    public func detectFaces(on image: CIImage) {
        detectFaces(on: image) { (result) in
            switch result {
            case .success(let faces):
                self.faceWasDetected(features: faces)
            case .error(let error):
                self.setStatus(.error(error.localizedDescription))
            }
        }
    }
    
    // MARK: Game/Countdown
    
    /// Starts the game and the countdown
    public func startInitialGame() {
        if isIntro {
            isPlaying = false
            isErrorRecoverable = true
            viewController.setCameraBlurred(true, emoji: "👋", title: "Welcome", description: "To play, use your face to imitate the emoji!\n\nTap anywhere to begin")
        } else if emojiTypes.count < 2 {
            isPlaying = false
            isErrorRecoverable = false
            viewController.setCameraBlurred(true, emoji: "⚠️", title: "Error", description: "Please set at least 2 different emoji types to play.")
            return
        } else {
            restartGame()
        }
    }
    
    /// Restarts the timer
    public func restartTimer() {
        timeLeft = 5
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countdown), userInfo: nil, repeats: true)
    }
    
    /// Restarts the game and the countdown
    private func restartGame() {
        guard !isPlaying, isErrorRecoverable else { return }
        score = 0
        timeLeft = 5
        isPlaying = true
        viewController.setCameraBlurred(false)
        setRandomEmoji()
        restartTimer()
    }
    
    /// Stops the timer
    public func stopTimer() {
        timer?.invalidate()
    }
    
    /// Called when the cover view is tapped - we restart the game or hide the message
    @objc func coverViewTapped() {
        if !isPlaying, isErrorRecoverable {
            restartGame()
        } else if !(viewController.statusLabel.text?.isEmpty ?? false) {
            setStatus(.none)
        }
    }
    
    /// Called every interval when the timer is running
    @objc func countdown() {
        guard !isIntro else { return }
        timeLeft -= 1
        
        if timeLeft < 0 {
            isPlaying = false
            stopTimer()
            isErrorRecoverable = true
            viewController.setCameraBlurred(true, emoji: "⏰", title: "Game Over", description: "Score: \(score)\n\nTap anywhere to restart")
        }
    }
    
    // MARK: CoreImage Face Detection
    
    /// Detects faces on the image with CoreImage and returns a Result containing the face features or an error
    private func detectFaces(on image: CIImage, completion: @escaping (Result<[CIFaceFeature]>) -> Void) {
        guard isPlaying, !isAnimating else { return }
        
        autoreleasepool(invoking: {
            let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorImageOrientation: viewController.orientation.cgImagePropertyOrientation]
            guard let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options) else {
                completion(.error(DetectionError.failedToSetUp))
                return
            }
            
            let featureOptions: [String: Any] = [CIDetectorSmile: true, CIDetectorEyeBlink: true]
            guard let faces = faceDetector.features(in: image, options: featureOptions) as? [CIFaceFeature] else {
                completion(.error(DetectionError.failedToDetect))
                return
            }
            
            if faces.isEmpty {
                viewController.isFaceInCameraCount += 1
            } else {
                viewController.isFaceInCameraCount = 0
            }
            
            completion(.success(faces))
        })
    }
    
    /// Called when a face was detected, checks for a match to the emoji
    private func faceWasDetected(features: [CIFaceFeature]) {
        guard let face = features.first else { return }
        
        if faceMatchesCurrentEmoji(face) {
            emojiMatches += 1
            
            if emojiMatches == 3 {
                emojiMatches = 0
                setRandomEmoji()
                timeLeft = 5
                stopTimer()
                viewController.timerLabel.setHidden(true)
            }
        } else {
            emojiMatches = 0
        }
    }
    
    /// Returns whether the face passed in matches the current emoji
    private func faceMatchesCurrentEmoji(_ face: CIFaceFeature) -> Bool {
        switch currentEmoji.category {
        case .smile:
            return face.hasSmile && !face.leftEyeClosed && !face.rightEyeClosed
        case .smileEyes:
            return face.hasSmile && face.leftEyeClosed && face.rightEyeClosed
        case .neutral:
            return !face.hasSmile && !face.leftEyeClosed && !face.rightEyeClosed
        case .neutralEyes:
            return !face.hasSmile && face.leftEyeClosed && face.rightEyeClosed
        case .wink:
            return face.hasSmile && (face.leftEyeClosed || face.rightEyeClosed) && (!face.leftEyeClosed || !face.rightEyeClosed)
        case .sleep:
            return !face.hasSmile && face.leftEyeClosed && face.rightEyeClosed
        }
    }

    // MARK: Status/Emoji
    
    /// Called when the emoji finishes animating
    private func emojiDidSet() {
        guard isPlaying else { return }
        viewController.timerLabel.setHidden(isIntro)
        isAnimating = false
        restartTimer()
    }
    
    /// Sets a random emoji
    private func setRandomEmoji() {
        var id: SystemSoundID = 1001
        AudioServicesCreateSystemSoundID(Bundle.main.url(forResource: "ding", withExtension: "mp3")! as CFURL, &id)
        AudioServicesPlaySystemSound(id)
        
        score += timeLeft * 5
        isAnimating = true
        viewController.timerLabel?.setHidden(true)
        
        let types = emojiTypes.filter { $0 != currentEmoji.category }
        currentEmoji = Emoji.random(oneOfTypes: types.isEmpty ? emojiTypes : types)
    }
    
    /// Sets the status label in the middle of the screen
    private func setStatus(_ status: Status) {
        viewController.setStatus(status)
    }
}
