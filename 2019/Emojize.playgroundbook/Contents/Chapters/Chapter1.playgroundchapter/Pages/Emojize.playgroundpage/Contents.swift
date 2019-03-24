//#-hidden-code
import PlaygroundSupport
var emojiTypes: Set<Emoji.Category>
//#-end-hidden-code
/*:
# **Emojize**
**Use your face to imitate the emoji that shows up as quickly as possible to gain points!**
 
---
 
## Countdown
Now that you've had a chance to play in the basic introduction, a countdown and score has been added. Be quick at playing or it's Game Over!
 
---
 
## Emoji Types
Change the array of emoji types below to change the types of emoji that show up.
*/
//#-code-completion(identifier, show, .smile, .smileEyes, .neutral, .neutralEyes, .wink, .sleep)
emojiTypes = [/*#-editable-code*/.smile, .smileEyes, .neutral, .neutralEyes, .wink, .sleep/*#-end-editable-code*/]
//#-hidden-code
if #available(iOS 11.0, *) {
    let manager = EmojizeGameManager(emojiTypes: Array(emojiTypes))
    PlaygroundPage.current.liveView = manager.viewController
}
//#-end-hidden-code
