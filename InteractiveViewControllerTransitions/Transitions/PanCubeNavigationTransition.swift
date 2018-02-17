//
//  PanCubeNavigationTransition.swift
//  InteractiveViewControllerTransitions
//
//  Created by Justin Rhoades on 16.02.18.
//  Copyright © 2018 Justin Rhoades. All rights reserved.
//

import UIKit

enum PanDirection {
    case Left
    case Right
}

class PanCubeNavigationTransition: NSObject {
    
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
    
    // Used for pan tracking
    var direction: PanDirection?
    
    func addGestures(toViewController:UIViewController) {
        viewController = toViewController
        
        let panGesture = UIPanGestureRecognizer(target: self, action:
            #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        viewController?.view.addGestureRecognizer(panGesture)
    }
    
    func performDefaultAnimation() {
        animator.addAnimations {
            self.viewController?.view.layer.transform = CATransform3DMakeTranslation(0.0, 0.0, 0.0)
        }
        animator.startAnimation()
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let screenWidth = UIScreen.main.bounds.width
        let maxDistance = screenWidth
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress = (abs(translation.x) / maxDistance)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
    
        switch gestureRecognizer.state {

        case .began:
            
            let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view!.superview!)
            if (velocity.x > 0) { direction = PanDirection.Left }
            if (velocity.x < 0) { direction = PanDirection.Right }
            
            interactionInProgress = true
            interactionController = UIPercentDrivenInteractiveTransition()
            viewController?.navigationController?.delegate = self

            if (direction == PanDirection.Right) {
                
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
            
            if (direction == PanDirection.Left) {
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
            shouldCompleteTransition = progress > 0.5
            interactionController?.update(progress)
            
            if (isEndOfStack) {
                // Allow manual dragging up to 1/2 the screen width
                // viewController?.view.layer.transform = CATransform3DMakeTranslation((screenWidth*0.5)*progress, 0.0, 0.0)
                var transform: CATransform3D = CATransform3DIdentity
                viewController?.view.layer.anchorPointZ = -((viewController?.view.frame.size.width)! / 2)
                transform = CATransform3DIdentity
                transform.m34 = -1.0 / 1000
                transform = CATransform3DTranslate(transform, 0, 0, (viewController?.view.layer.anchorPointZ)!)
                viewController?.view.layer.transform = transform
                if (direction == PanDirection.Right) { progress = progress * -1 }
                viewController?.view.layer.transform = CATransform3DRotate((viewController?.view.layer.transform)!, (CGFloat(Double.pi/4))*progress, 0, 1, 0)
    
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

extension PanCubeNavigationTransition: UIGestureRecognizerDelegate {
    
}

extension PanCubeNavigationTransition: UIViewControllerAnimatedTransitioning {
    
    // Duration of the animation
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1.0
    }
    
    // The actual animation
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        // Get the necessary references the view controllers that are transitioning
        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
            else {
                return
        }
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        // Prepare the fromView
        fromVC.view.layer.anchorPointZ = -((fromVC.view.frame.size.width) / 2)
        var transform: CATransform3D = CATransform3DIdentity
        transform.m34 = -1.0 / 1000
        transform = CATransform3DTranslate(transform, 0, 0, (fromVC.view.layer.anchorPointZ))
        fromVC.view.layer.transform = transform
        fromVC.view.layer.borderColor = UIColor.black.cgColor
        fromVC.view.layer.borderWidth = 1.0
        
        // Temp layer to create the darkening effect of the from view
        let fromFadeOutView = UIView(frame: fromVC.view.frame)
        fromFadeOutView.backgroundColor = UIColor.black
        fromFadeOutView.layer.opacity = 0
        fromVC.view.addSubview(fromFadeOutView)

        // Prepare the toView
        toVC.view.frame = fromVC.view.frame
        toVC.view.layer.anchorPointZ = -((toVC.view.frame.size.width) / 2)
        transform = CATransform3DIdentity
        transform.m34 = -1.0 / 1000
        transform = CATransform3DTranslate(transform, 0, 0, (toVC.view.layer.anchorPointZ))
        toVC.view.layer.transform = transform
        
        // Temp layer to create the darkening effect of the from view
        let toFadeOutView = UIView(frame: toVC.view.frame)
        toFadeOutView.backgroundColor = UIColor.black
        toFadeOutView.layer.opacity = 0.75
        toVC.view.addSubview(toFadeOutView)
        
        // Position and rotate the toView to the right or left depending on the operation
        switch operation {
        case .push:
            // To view goes on top for push
            containerView.addSubview(fromVC.view)
            containerView.addSubview(toVC.view)
            toVC.view.layer.transform = CATransform3DRotate((toVC.view.layer.transform), CGFloat(Double.pi / 2), 0, 1, 0)
            
        case .pop:
            // From view goes on top for push
            containerView.addSubview(toVC.view)
            containerView.addSubview(fromVC.view)
            toVC.view.layer.transform = CATransform3DRotate((toVC.view.layer.transform), CGFloat(-Double.pi/2), 0, 1, 0)
            
        case .none:
            return
        }
        
        // Do the animation
        UIView.animate(withDuration: duration, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            switch self.operation {
            case .push:
                toVC.view.layer.transform = CATransform3DRotate((toVC.view.layer.transform), CGFloat(-Double.pi / 2), 0, 1, 0)
                fromVC.view.layer.transform = CATransform3DRotate((fromVC.view.layer.transform), CGFloat(-Double.pi / 2), 0, 1, 0)
                //fromVC.view.layer.opacity = 0.5
                fromFadeOutView.layer.opacity = 1.0
                toFadeOutView.layer.opacity = 0.0
            case .pop:
                toVC.view.layer.transform = CATransform3DRotate((toVC.view.layer.transform), CGFloat(Double.pi / 2), 0, 1, 0)
                fromVC.view.layer.transform = CATransform3DRotate((fromVC.view.layer.transform), CGFloat(Double.pi / 2), 0, 1, 0)
                //fromVC.view.layer.opacity = 0.1
                fromFadeOutView.layer.opacity = 0.5
                toFadeOutView.layer.opacity = 0.0
            case .none:
                return
            }
            
        }, completion: {(value: Bool) in
            // Get rid of the temp fadeout layer
            toFadeOutView.removeFromSuperview()
            fromFadeOutView.removeFromSuperview()
            
            // Get rid of the border we added
            fromVC.view.layer.borderColor = UIColor.clear.cgColor
            fromVC.view.layer.borderWidth = 0.0
            
            // Reset the view transforms
            toVC.view.layer.transform = CATransform3DIdentity
            toVC.view.layer.opacity = 1.0
            toVC.view.layer.anchorPointZ = 0
            
            fromVC.view.layer.transform = CATransform3DIdentity
            fromVC.view.layer.opacity = 1.0
            fromVC.view.layer.anchorPointZ = 0
            
            // Gotta call this to let UIKit know that we're done
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            // Reset the navigationController delegate if they exist
            // Necessary for subsequent expected nav controller behavior
            fromVC.navigationController?.delegate = nil
            toVC.navigationController?.delegate = nil
        })
    }
}

extension PanCubeNavigationTransition: UINavigationControllerDelegate {
    
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
