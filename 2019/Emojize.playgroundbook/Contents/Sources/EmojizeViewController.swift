//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  An auxiliary source file which is part of the book-level auxiliary sources.
//  Provides the implementation of the "always-on" live view.
//

import AVKit
import CoreImage
import PlaygroundSupport
import UIKit
import Vision

@available(iOS 11.0, *)
@objc(Book_Sources_LiveViewController)
public class EmojizeViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    
    let manager: EmojizeGameManager
    
    var isFaceInCameraCount = 0 {
        didSet {
            DispatchQueue.main.async {
                guard self.manager.isPlaying else { return }
                if self.isFaceInCameraCount == 0, !self.coverView.isHidden {
                    self.manager.restartTimer()
                    self.setCameraBlurred(false)
                } else if self.isFaceInCameraCount > 30 {
                    self.manager.stopTimer()
                    self.setCameraBlurred(true)
                }
            }
        }
    }
    
    var coverView: UIVisualEffectView!
    var coverViewEmoji: UILabel!
    var coverViewTitle: UILabel!
    var coverViewDescription: UILabel!
    var coverViewGestureRecognizer: UITapGestureRecognizer!
    
    var previewView: UIImageView!
    var scoreLabel: EmbeddedLabel!
    var timerLabel: EmbeddedLabel!
    var emojiLabel: EmojiLabel!
    var statusLabel: EmbeddedLabel!
    
    var session = AVCaptureSession()
    var videoDataOutput: AVCaptureVideoDataOutput? = AVCaptureVideoDataOutput()
    var videoDataOutputQueue = DispatchQueue(label: "FaceTrack")
    
    var captureDevice: AVCaptureDevice!
    var captureDeviceResolution = CGSize()
    
    func setScore(_ score: String) {
        DispatchQueue.main.async {
            if self.manager.isIntro {
                self.scoreLabel.text = "Introduction"
            } else {
                self.scoreLabel.text = "Score: \(score)"
            }
        }
    }
    
    func setStatus(_ status: Status) {
        DispatchQueue.main.async {
            self.statusLabel.attributedText = status.attributedString
            
            switch status {
            case .none:
                self.statusLabel.setHidden(true)
            default:
                self.statusLabel.setHidden(false)
            }
        }
    }
    
    func countdown(to time: Int) {
        DispatchQueue.main.async {
            self.timerLabel.text = String(time)
            if time < 3 {
                self.timerLabel.textColor = .red
            } else {
                self.timerLabel.textColor = .white
            }
        }
    }
    
    func setCameraBlurred(_ blurred: Bool, emoji: String = "🤔", title: String = "Face Not Found", description: String = "Please position your face in the camera frame to play.") {
        DispatchQueue.main.async {
            self.coverViewEmoji.text = emoji
            self.coverViewTitle.text = title
            self.coverViewDescription.text = description
            
            if blurred {
                self.coverView.isHidden = false
                UIView.animate(withDuration: 0.4) {
                    self.coverView.effect = UIBlurEffect(style: .dark)
                    self.statusLabel.setHidden(true)
                    self.timerLabel.setHidden(true)
                    self.scoreLabel.setHidden(true)
                    self.emojiLabel.setHidden(true)
                }
            } else {
                UIView.animate(withDuration: 0.05, animations: {
                    self.coverView.effect = nil
                    self.statusLabel.setHidden(self.statusLabel.text?.isEmpty ?? true)
                    self.timerLabel.setHidden(self.manager.isIntro)
                    self.scoreLabel.setHidden(false)
                    self.emojiLabel.setHidden(false)
                }, completion: { _ in
                    self.coverView.isHidden = true
                })
            }
        }
    }
    
    /// Creates a new `EmojizeViewController` with the specified manager
    public init(manager: EmojizeGameManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Loads the views and sets up the capture session to display the camera output
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupPreviewView()
        setupScoreLabel()
        setupTimerLabel()
        setupStatusLabel()
        emojiLabel = EmojiLabel(superview: view, guide: liveViewSafeAreaGuide)
        
        setupCoverView()
        
        do {
            try configureCaptureSession()
            session.startRunning()
        } catch {
            throwError(.error(error))
            teardownAVCapture()
        }
    }
    
    /// Start the game when the view appears on screen
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager.startInitialGame()
    }
    
    /// Sets up the preview view to show the camera output
    func setupPreviewView() {
        previewView = UIImageView(image: UIImage(named: "example"))
        previewView.transform = CGAffineTransform(scaleX: -1, y: 1)
        previewView.contentMode = .scaleAspectFill
        previewView.backgroundColor = .darkGray
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        
        previewView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    /// Sets up the score label with the default text and position
    func setupScoreLabel() {
        scoreLabel = EmbeddedLabel(text: "", size: 30, radius: 10, superview: view)
        
        scoreLabel.containerView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 20).isActive = true
        scoreLabel.containerView.leadingAnchor.constraint(equalTo: liveViewSafeAreaGuide.leadingAnchor, constant: 20).isActive = true
        scoreLabel.containerView.trailingAnchor.constraint(lessThanOrEqualTo: liveViewSafeAreaGuide.trailingAnchor, constant: -20).isActive = true
    }
    
    /// Sets up the timer label with the default text and position
    func setupTimerLabel() {
        timerLabel = EmbeddedLabel(text: "5", size: 30, radius: 10, superview: view)
        timerLabel.setHidden(manager.isIntro)
        
        timerLabel.containerView.topAnchor.constraint(equalTo: liveViewSafeAreaGuide.topAnchor, constant: 20).isActive = true
        timerLabel.containerView.trailingAnchor.constraint(equalTo: liveViewSafeAreaGuide.trailingAnchor, constant: -20).isActive = true
    }
    
    /// Sets up the status label with the default text and position
    func setupStatusLabel() {
        statusLabel = EmbeddedLabel(text: "", size: 35, radius: 10, superview: view)
        statusLabel.setHidden(true)
        statusLabel.font = UIFont.boldSystemFont(ofSize: 35)
        
        statusLabel.containerView.centerXAnchor.constraint(equalTo: liveViewSafeAreaGuide.centerXAnchor).isActive = true
        statusLabel.containerView.centerYAnchor.constraint(equalTo: liveViewSafeAreaGuide.centerYAnchor).isActive = true
        statusLabel.containerView.leadingAnchor.constraint(lessThanOrEqualTo: liveViewSafeAreaGuide.leadingAnchor, constant: 20).isActive = true
        statusLabel.containerView.trailingAnchor.constraint(lessThanOrEqualTo: liveViewSafeAreaGuide.trailingAnchor, constant: -20).isActive = true
    }
    
    /// Sets up the cover view with the default text and position
    func setupCoverView() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        containerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        coverView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        coverView.isHidden = true
        coverView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        coverView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(coverView)
        coverView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        coverView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        coverView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        coverView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        
        coverViewEmoji = UILabel()
        coverViewEmoji.text = "🤔"
        coverViewEmoji.font = UIFont.systemFont(ofSize: 80)
        coverViewEmoji.textColor = .white
        coverViewEmoji.textAlignment = .center
        coverViewEmoji.translatesAutoresizingMaskIntoConstraints = false
        coverView.contentView.addSubview(coverViewEmoji)
        coverViewEmoji.centerYAnchor.constraint(equalTo: coverView.contentView.centerYAnchor, constant: -50).isActive = true
        coverViewEmoji.leadingAnchor.constraint(equalTo: coverView.contentView.leadingAnchor, constant: 20).isActive = true
        coverViewEmoji.trailingAnchor.constraint(equalTo: coverView.contentView.trailingAnchor, constant: -20).isActive = true
        
        let statusVibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
        statusVibrancyView.translatesAutoresizingMaskIntoConstraints = false
        coverView.contentView.addSubview(statusVibrancyView)
        statusVibrancyView.topAnchor.constraint(equalTo: coverViewEmoji.bottomAnchor, constant: 10).isActive = true
        statusVibrancyView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        statusVibrancyView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20).isActive = true
        
        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        statusVibrancyView.contentView.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: statusVibrancyView.contentView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: statusVibrancyView.contentView.bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: statusVibrancyView.contentView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: statusVibrancyView.contentView.trailingAnchor).isActive = true
        
        coverViewTitle = UILabel()
        coverViewTitle.text = "Face Not Found"
        coverViewTitle.font = UIFont.systemFont(ofSize: 40, weight: .heavy)
        coverViewTitle.textColor = .white
        coverViewTitle.numberOfLines = 0
        coverViewTitle.textAlignment = .center
        coverViewTitle.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(coverViewTitle)
        
        coverViewDescription = UILabel()
        coverViewDescription.text = "Please position your face in the camera frame to play."
        coverViewDescription.font = UIFont.systemFont(ofSize: 22)
        coverViewDescription.textColor = .white
        coverViewDescription.numberOfLines = 0
        coverViewDescription.textAlignment = .center
        coverViewDescription.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(coverViewDescription)
        
        coverViewGestureRecognizer = UITapGestureRecognizer(target: manager, action: #selector(EmojizeGameManager.coverViewTapped))
        view.addGestureRecognizer(coverViewGestureRecognizer)
    }
    
    // MARK: AVCaptureSession Setup
    
    /// Sets up the AVCaptureSession and data output.
    fileprivate func configureCaptureSession() throws {
        //
        guard UIImagePickerController.isCameraDeviceAvailable(.front) else { return }
        
        // Find the best front camera device that matches our need and the highest resolution for it
        guard let discoveredDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first,
            let highestResolution = discoveredDevice.bestResolutionFormat() else {
                throw AVError.failedToSetUp
        }
        
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Set up the input device
        let inputDevice = try AVCaptureDeviceInput(device: discoveredDevice)
        captureDevice = inputDevice.device
        captureDeviceResolution = highestResolution.resolution
        
        // Set up the camera device
        try discoveredDevice.lockForConfiguration()
        discoveredDevice.activeFormat = highestResolution.format
        discoveredDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
        discoveredDevice.unlockForConfiguration()
        
        // Set up the video data output
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        videoDataOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        updateOrientation()
        
        if session.canAddInput(inputDevice), session.canAddOutput(videoDataOutput!) {
            session.addInput(inputDevice)
            session.addOutput(videoDataOutput!)
            videoDataOutput?.connection(with: .video)?.isEnabled = true
        } else {
            throw AVError.failedToSetUp
        }
        
        if let captureConnection = videoDataOutput?.connection(with: AVMediaType.video), captureConnection.isCameraIntrinsicMatrixDeliverySupported {
            captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
        }
        
        session.commitConfiguration()
    }
    
    /// Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownAVCapture() {
        self.videoDataOutput = nil
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    
    /// Handle delegate method callback on receiving a sample buffer.
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let image = UIImage(pixelBuffer: pixelBuffer) else {
                fatalError("Failed to obtain a CVPixelBuffer for the current output frame.")
        }
        
        DispatchQueue.main.async {
            self.previewView.image = image
        }
        
        self.manager.detectFaces(on: CIImage(cvImageBuffer: pixelBuffer))
    }
    
    // MARK: Error Handling
    
    /// A type of error
    enum ErrorType {
        case error(Error)
        case text(String)
        case other
    }
    
    /// Shows an alert with a title and message
    fileprivate func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(alertController, animated: true)
    }
    
    /// Shows an alert to notify the user of an error that occured
    fileprivate func throwError(_ error: ErrorType) {
        switch error {
        case .error(let error):
            showAlert(title: "An error occured", message: error.localizedDescription)
            print(error.localizedDescription)
            setStatus(.error(error.localizedDescription))
        case .text(let error):
            showAlert(title: "An error occured", message: error)
            setStatus(.error(error))
        case .other:
            showAlert(title: "Error", message: "An unexpected error has occured.")
            setStatus(.error("An unknown error occured."))
        }
    }
    
    // MARK: Orientation Workarounds
    
    /// Returns the interface orientation
    /// ****************************************************************************************************************************************
    /// *** IMPORTANT: Due to orientation issues in Swift Playground, we MUST use the DEPRECATED `interfaceOrientation` or it will not work! ***
    /// ****************************************************************************************************************************************
    public var orientation: UIInterfaceOrientation {
        return interfaceOrientation
    }
    
    /// Updates the orientation of the camera to match the interface orientation
    @objc func updateOrientation() {
        _ = orientation
        videoDataOutput?.connection(with: .video)?.videoOrientation = orientation.avCaptureOrientation
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let wasCameraBlurred = coverView.isHidden
        
        if !wasCameraBlurred { setCameraBlurred(true, emoji: "", title: "", description: "") }
        session.stopRunning()
        updateOrientation()
        
        // The orientation sometimes isn't set until the size has been adjusted.
        // We call `updateOrientation()` again during and after the transition to make sure.
        coordinator.animate(alongsideTransition: { _ in
            self.updateOrientation()
        }) { _ in
            self.updateOrientation()
            self.session.startRunning()
            if !wasCameraBlurred { self.setCameraBlurred(false, emoji: "", title: "", description: "") }
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateOrientation()
    }

    public func receive(_ message: PlaygroundValue) {
        // Implement this method to receive messages sent from the process running Contents.swift.
        // This method is *required* by the PlaygroundLiveViewMessageHandler protocol.
        // Use this method to decode any messages sent as PlaygroundValue values and respond accordingly.
    }
}
