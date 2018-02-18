# Interactive View Controller Transitions
Easy to use custom interactive navigation controller transitions that work alongside storyboards.
![A screen capture from the example app](https://img.jmrhoades.com/ivct_capture_01c.gif)


## Try it
1. Download the example project
2. Locate the transition classes (like `PanCubeNavigationTransition.swift`) and add them to your project
3. Create a transition object `var transition = PanCubeNavigationTransition()`
4. Attach the transition's gestures to your view controller `transition.addGestures(toViewController:self)`
5. Optionally add a storyboard ID for `push` transitions `transition.nextStoryboardID = "SecondViewController"`
![The example app](https://img.jmrhoades.com/ivct_xcode_01.jpg)


## Why?
After getting vaguely acquainted with the UIKit view controller transitioning APIs via this essential 2013 WWDC talk [Custom Transitions Using View Controllers](https://developer.apple.com/videos/play/wwdc2013/218/), I wanted to create a dead-simple, drop-in transition helper that would play nice with storyboard-based projects. This approach led to self-contained classes that encapsulate the necessary gesture recognizers, transitioning protocols, navigation delegates and animations required to express a complete thought around an interactive transition.
