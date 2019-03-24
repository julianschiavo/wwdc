//
//  Emoji.swift
//  Book_Sources
//
//  Created by Julian Schiavo on 23/3/2019.
//

import UIKit

/// A emoji from the entire list of available emojis
public enum Emoji: String, CaseIterable {
    /// A category of emoji
    public enum Category: CaseIterable {
        case smile
        case smileEyes
        case neutral
        case neutralEyes
        case wink
        case sleep
        
        var all: [Emoji] {
            return Emoji.allCases.filter { $0.category == self }
        }
    }
    
    // Smile Emoji
    case 😀
    case 😃
    case 😄
    case 😁
    case 😊
    case 🙂
    case 😇
    
    // Smile with closed eye Emoji
    case 😌
    
    // Neutral Emoji
    case 😐
    case 😕
    case 🙁
    
    // Neutral with closed eyes Emoji
    case 😑
    
    // Wink Emoji
    case 😉
    
    // Sleep Emoji
    case 😴
    
    /// The category that the emoji is in
    var category: Category {
        switch self {
        case .😀, .😃, .😄, .😁, .😊, .🙂, .😇:
            return .smile
        case .😌:
            return .smileEyes
        case .😐, .😕, .🙁:
            return .neutral
        case .😑:
            return .neutralEyes
        case .😉:
            return .wink
        case .😴:
            return .sleep
        }
    }
    
    /// Returns a random emoji that is in one of the categories
    static func random(oneOfTypes types: [Category]) -> Emoji {
        var possible = [Emoji]()
        for type in Category.allCases where types.contains(type) {
            possible.append(contentsOf: type.all)
        }
        return possible.randomElement() ?? allCases.randomElement() ?? .😀
    }
}
