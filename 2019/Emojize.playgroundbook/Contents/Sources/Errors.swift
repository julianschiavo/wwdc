//
//  Emoji.swift
//  Book_Sources
//
//  Created by Julian Schiavo on 23/3/2019.
//

import Foundation

/// A type of AVError
enum AVError: Error {
    case failedToSetUp
    
    var localizedDescription: String {
        switch self {
        case .failedToSetUp:
            return "Failed to set up the camera."
        }
    }
}

/// A type of error with the face detection
enum DetectionError: Error {
    case failedToSetUp
    case failedToDetect
    
    var localizedDescription: String {
        switch self {
        case .failedToDetect:
            return "Failed to detect a face."
        default:
            return ""
        }
    }
}
