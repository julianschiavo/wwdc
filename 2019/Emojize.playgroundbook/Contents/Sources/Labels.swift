//
//  Labels.swift
//  Book_Sources
//
//  Created by Julian Schiavo on 23/3/2019.
//

import UIKit

/// A UILabel embedded within a visual effect container view
public class EmbeddedLabel: UILabel {
    var containerView: UIView!
    
    /// Sets the label's container to hidden to avoid an empty container on the screen
    public func setHidden(_ hidden: Bool) {
        DispatchQueue.main.async {
            self.containerView.isHidden = hidden
        }
    }
    
    init() {
        super.init(frame: .zero)
    }
    
    /// Creates a new `EmbeddedLabel` within a visual effect view with the specified paremeters
    init(text: String, size: CGFloat, color: UIColor = .white, radius: CGFloat = 20, vibrancy: Bool = true, superview: UIView) {
        containerView = UIView()
        containerView.backgroundColor = .darkGray
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = radius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(containerView)
        
        super.init(frame: .zero)
        self.text = text
        font = UIFont.systemFont(ofSize: size)
        textColor = color
        textAlignment = .center
        translatesAutoresizingMaskIntoConstraints = false
        embedInVisualEffectView(style: .dark, vibrancy: vibrancy, padding: 10, superview: containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A special UILabel containing a large emoji within a visual effect view with support for animating
public class EmojiLabel: EmbeddedLabel {
    var topView: UIView!
    
    var normalAnchors = [NSLayoutConstraint]()
    var largeAnchors = [NSLayoutConstraint]()
    
    /// Sets the label's emoji, using a special animation with fixed values
    func setEmoji(_ emoji: Emoji, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.text = emoji.rawValue
            self.containerView.alpha = 1
            
            UIView.animate(withDuration: 0, animations: {
                self.containerView.alpha = 0
                self.containerView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                NSLayoutConstraint.activate(self.largeAnchors)
                NSLayoutConstraint.deactivate(self.normalAnchors)
                self.topView.layoutIfNeeded()
            }, completion: { (_) in
                UIView.animate(withDuration: 0.2, animations: {
                    self.containerView.alpha = 1
                }, completion: { (_) in
                    UIView.animate(withDuration: 0.4, delay: 1, animations: {
                        self.containerView.transform = .identity
                        NSLayoutConstraint.deactivate(self.largeAnchors)
                        NSLayoutConstraint.activate(self.normalAnchors)
                        self.topView.layoutIfNeeded()
                    }, completion: { (_) in
                        completion()
                    })
                })
            })
        }
    }
    
    /// Creates a new `EmojiLabel` in the superview, constraining it to the layout guide
    init(superview: UIView, guide: UILayoutGuide) {
        topView = superview
        super.init()
        
        containerView = UIView()
        containerView.backgroundColor = .darkGray
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(containerView)
        
        containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        normalAnchors = [
            containerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -20),
            containerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor, constant: -20)
        ]
        NSLayoutConstraint.activate(normalAnchors)
        
        largeAnchors = [
            containerView.centerXAnchor.constraint(equalTo: topView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: topView.centerYAnchor)
        ]
        
        text = "😀"
        font = UIFont.systemFont(ofSize: 100)
        textColor = .white
        textAlignment = .center
        translatesAutoresizingMaskIntoConstraints = false
        embedInVisualEffectView(style: .dark, vibrancy: false, padding: 10, superview: containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
