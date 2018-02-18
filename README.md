# Interactive View Controller Transitions
Easy to use custom interactive navigation controller transitions that work alongside storyboards

![The example app](https://img.jmrhoades.com/ivct_xcode_01.jpg)

## Try It
1. Download the example project
2. Locate the transition classes (like `PanCubeNavigationTransition.swift`) and add them to your project
3. Create a transition object `var transition = PanCubeNavigationTransition()`
4. Attach the transition's gestures to your view controller `transition.addGestures(toViewController:self)`
5. Optionally add a storyboard ID for `push` transitions `transition.nextStoryboardID = "SecondViewController"`

