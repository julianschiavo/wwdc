import AVFoundation
import UIKit

/// A type for use with completion handlers to either return a value or an error
public enum Result<Value> {
    case success(Value)
    case error(Error)
    
    init(success value: Value) {
        self = .success(value)
    }
    
    init(error: Error) {
        self = .error(error)
    }
    
    var success: Value? {
        switch self {
        case .success(let value): return value
        case .error: return nil
        }
    }
    
    var error: Error? {
        switch self {
        case .success: return nil
        case .error(let value): return value
        }
    }
}

public extension AVCaptureDevice {
    /// Returns the best resolution and format for this device
    public func bestResolutionFormat() -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
        var highestResolutionFormat: AVCaptureDevice.Format?
        var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)
        
        for format in formats where CMFormatDescriptionGetMediaSubType(format.formatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
            let candidateDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if highestResolutionFormat == nil || candidateDimensions.width > highestResolutionDimensions.width {
                highestResolutionFormat = format
                highestResolutionDimensions = candidateDimensions
            }
        }
        
        if highestResolutionFormat != nil {
            let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
            return (highestResolutionFormat!, resolution)
        }
        
        return nil
    }
}

public extension UIImage {
    /// Creates a `UIImage` from a `CVPixelBuffer` which is in either the 32ARGB or 32BGRA format
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let bitmapInfo: CGBitmapInfo
        
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        if sourcePixelFormat == kCVPixelFormatType_32ARGB {
            bitmapInfo = [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
        } else if sourcePixelFormat == kCVPixelFormatType_32BGRA {
            bitmapInfo = [.byteOrder32Little, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
        } else {
            return nil
        }
        
        let sourceRowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        guard let sourceBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
            let provider = CGDataProvider(dataInfo: nil, data: sourceBaseAddress, size: sourceRowBytes * height, releaseData: {_,_,_ in }),
            let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: sourceRowBytes,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: provider, decode: nil,
                                shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent) else { return nil }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        self.init(cgImage: image)
    }
}

public extension UIInterfaceOrientation {
    /// The orientation converted to an `AVCaptureVideoOrientation`
    public var avCaptureOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .portrait
        }
    }
    
    /// The orientation converted to a `CGImagePropertyOrientation`
    public var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        default:
            return .right
        }
    }
}

public extension UIView {
    /// Embeds the view in a visual effect view with the parameters
    @discardableResult public func embedInVisualEffectView(style: UIBlurEffect.Style, vibrancy: Bool, center: Bool = false, padding: CGFloat, superview: UIView) -> UIVisualEffectView {
        let statusEffectView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        statusEffectView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        statusEffectView.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(statusEffectView)
        statusEffectView.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        statusEffectView.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        statusEffectView.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        statusEffectView.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        
        if vibrancy {
            let statusVibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: style)))
            statusVibrancyView.translatesAutoresizingMaskIntoConstraints = false
            statusEffectView.contentView.addSubview(statusVibrancyView)
            statusVibrancyView.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            statusVibrancyView.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            statusVibrancyView.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
            statusVibrancyView.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
            statusVibrancyView.contentView.addSubview(self)
        } else {
            statusEffectView.contentView.addSubview(self)
        }
        
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: statusEffectView.contentView.leadingAnchor, constant: padding).isActive = true
        trailingAnchor.constraint(equalTo: statusEffectView.contentView.trailingAnchor, constant: -padding).isActive = true
        if center {
            centerYAnchor.constraint(equalTo: statusEffectView.contentView.centerYAnchor).isActive = true
        } else {
            topAnchor.constraint(equalTo: statusEffectView.contentView.topAnchor, constant: padding).isActive = true
            bottomAnchor.constraint(equalTo: statusEffectView.contentView.bottomAnchor, constant: -padding).isActive = true
        }
        
        return statusEffectView
    }
}
