//#-hidden-code
import PlaygroundSupport
//#-end-hidden-code
/*:
# **Emojize**

**Use your face to imitate the emoji that shows up!**
 
When you're done with the introduction, tap below to continue to the next page.
 
---
 
## How to play
1. Tap "Run My Code"
2. An emoji will show up on the bottom left of the screen
3. Make the emoji with your face as fast as you can!
4. After trying it out, tap below to continue to the next page
 
---
 
[Tap here to continue](Emojize)
 */
//#-hidden-code
if #available(iOS 11.0, *) {
    let manager = EmojizeGameManager(isIntro: true)
    PlaygroundPage.current.liveView = manager.viewController
}
//#-end-hidden-code
