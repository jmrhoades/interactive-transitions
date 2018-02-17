//
//  PinchNavigationTransition.swift
//  InteractiveViewControllerTransitions
//
//  Created by Justin Rhoades on 15.02.18.
//  Copyright © 2018 Justin Rhoades. All rights reserved.
//

import UIKit

enum PinchDirection {
    case Out
    case In
}

class PinchScaleNavigationTransition: NSObject {

    // Gets set when addGestures(toViewController:) is called, necessary for anything to happen
    var viewController: UIViewController?
    
    // This must be set by the view controller for right edge swiping to work
    var nextStoryboardID:String?
    
    // Used for interactive view controller transitioning
    var operation: UINavigationControllerOperation = .none
    var interactionController: UIPercentDrivenInteractiveTransition?
    var interactionInProgress = false
    var shouldCompleteTransition = false
    
    // Used for canned end-of-stack animations
    var isEndOfStack = false
    var animator = UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.50)
    
    // Used for pinch tracking
    var initialScale:CGFloat = 0.0
    var direction: PinchDirection?

    func addGestures(toViewController:UIViewController) {
        viewController = toViewController
        let pinchGesture = UIPinchGestureRecognizer(target: self, action:
            #selector(handlePinchGesture(_:)))
        pinchGesture.delegate = self
        viewController?.view.addGestureRecognizer(pinchGesture)
    }
    
    func performDefaultAnimation() {
        animator.addAnimations {
            self.viewController?.view.layer.transform = CATransform3DMakeTranslation(0.0, 0.0, 0.0)
            self.viewController?.view.layer.opacity = 1.0
        }
        animator.startAnimation()
    }
    
    @objc func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        
        switch gestureRecognizer.state {
            
        case .began:
            initialScale = gestureRecognizer.scale
            
            let velocity = gestureRecognizer.velocity
            if (velocity > 0) { direction = PinchDirection.Out }
            if (velocity < 0) { direction = PinchDirection.In }
            
            interactionInProgress = true
            interactionController = UIPercentDrivenInteractiveTransition()
            viewController?.navigationController?.delegate = self
            
            if (direction == PinchDirection.In) {
                if (nextStoryboardID == nil) {
                    isEndOfStack = true
                } else {
                    // Deal with navigation controller / Storyboard
                    let vc = viewController?.storyboard!.instantiateViewController(withIdentifier: nextStoryboardID!)
                    if (vc == nil) {
                        // nextStoryboardID was present but the view controller couldn't be loaded
                        isEndOfStack = true
                    } else {
                        // Kick off the standard push view controller animation
                        viewController?.navigationController?.delegate = self
                        viewController?.navigationController?.pushViewController(vc!, animated: true)
                        isEndOfStack = false
                    }
                }
            }
            if (direction == PinchDirection.Out) {
                // Kick off the standard pop view controller animation
                let vc = viewController?.navigationController?.popViewController(animated: true)
                if (vc == nil) {
                    isEndOfStack = true
                    viewController?.navigationController?.delegate = nil
                } else {
                    isEndOfStack = false
                }
            }
            
        case .changed:
            var progress = 1 - gestureRecognizer.scale
            if (direction == PinchDirection.Out) {
                progress = (gestureRecognizer.scale-initialScale) / 4
            }
            shouldCompleteTransition = progress > 0.5
            interactionController?.update(progress)
            
            if (isEndOfStack) {
                var scale = 1 + (0.25 * progress)
                if (direction == PinchDirection.In) { scale = 1 - (0.25 * progress) }
                viewController?.view.layer.transform = CATransform3DMakeScale(scale, scale, scale)
                viewController?.view.layer.opacity = Float(1 - (0.75 * progress))
                viewController?.navigationController?.delegate = nil
                interactionInProgress = false
            }
            
        case .cancelled:
            interactionInProgress = false
            interactionController?.cancel()
            
        case .ended:
            interactionInProgress = false
            if shouldCompleteTransition {
                interactionController?.finish()
            } else {
                interactionController?.cancel()
            }
            if (isEndOfStack) {
                performDefaultAnimation()
            }
        default:
            break
        }
    }
}

extension PinchScaleNavigationTransition: UIGestureRecognizerDelegate {
    
}

extension PinchScaleNavigationTransition: UIViewControllerAnimatedTransitioning {
    
    // Duration of the animation
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1.0
    }
    
    // The actual animation
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
            else {
                return
        }
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        let screenWidth = UIScreen.main.bounds.width
        
        switch operation {
        case .push:
            
            containerView.addSubview(toVC.view)
            
            // Place the new view offscreen just off the right edge
            toVC.view.layer.transform = CATransform3DMakeTranslation(screenWidth, 0.0, 0.0)
            
            // Add a shadow
            toVC.view.layer.shadowColor = UIColor.black.cgColor
            toVC.view.layer.shadowOpacity = 0.05
            toVC.view.layer.shadowOffset = CGSize.zero
            toVC.view.layer.shadowRadius = 10
            toVC.view.layer.shadowPath = UIBezierPath(rect: toVC.view.bounds).cgPath
            
            UIView.animateKeyframes(
                withDuration: duration,
                delay: 0,
                options: .calculationModeLinear,
                animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                        //fromVC.view.layer.transform = CATransform3DMakeTranslation(-screenWidth/3, 0.0, 0.0)
                        fromVC.view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 0.5)
                        fromVC.view.layer.opacity = 0.5
                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                        toVC.view.layer.transform = CATransform3DMakeTranslation(0.0, 0.0, 0.0)
                    }
            },
                completion: { _ in
                    
                    // Reset the transforms
                    fromVC.view.layer.transform = CATransform3DIdentity
                    fromVC.view.layer.opacity = 1.0
                    toVC.view.layer.transform = CATransform3DIdentity
                    toVC.view.layer.shadowOpacity = 0.0
                    
                    // Gotta call this
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    
                    // Reset the navigationController delegate if they exist
                    // Necessary for subsequent expected nav controller behavior
                    fromVC.navigationController?.delegate = nil
                    toVC.navigationController?.delegate = nil
            })
            
        case .pop:

            containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
            
            // Place the new view offscreen just off the left edge
            toVC.view.layer.transform = CATransform3DMakeTranslation(-screenWidth, 0.0, 0.0)
            //toVC.view.layer.opacity = 0.5
            
            UIView.animateKeyframes(
                withDuration: duration,
                delay: 0,
                options: .calculationModeLinear,
                animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                        fromVC.view.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5)
                        fromVC.view.layer.opacity = 0.5

                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                        toVC.view.layer.transform = CATransform3DMakeTranslation(0, 0.0, 0.0)
                        toVC.view.layer.opacity = 1.0
                    }
            },
                completion: { _ in
                    fromVC.view.layer.transform = CATransform3DIdentity
                    fromVC.view.layer.opacity = 1.0

                    toVC.view.layer.transform = CATransform3DIdentity

                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    
                    // Reset the navigationController delegates if they exist
                    fromVC.navigationController?.delegate = nil
                    toVC.navigationController?.delegate = nil
            })
            
        case .none:
            // Break here because I'm not sure when or if this case could occur
            return
        }
    }
}

extension PinchScaleNavigationTransition: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // Remember the direction of the transition (.push or .pop)
        self.operation = operation
        // Return ourselves as the animation controller for the pending transition
        return self
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // Return ourselves as the interaction controller for the pending transition
        return self.interactionController
    }
}
