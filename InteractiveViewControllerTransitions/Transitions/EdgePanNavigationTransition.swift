//
//  PanViewGestureAnimation.swift
//  InteractiveViewControllerTransitions
//
//  Created by Justin Rhoades on 31.01.18.
//  Copyright © 2018 Justin Rhoades. All rights reserved.
//

import UIKit

class EdgePanNavigationTransition: NSObject {
    
    // Gets set when addGestures(toViewController:) is called, necessary for anything to happen
    private var viewController: UIViewController?
    
    // This must be set by the view controller for right edge swiping to work
    public var nextStoryboardID:String?
    
    // Used for interactive view controller transitioning
    private var operation: UINavigationControllerOperation = .none
    private var interactionController: UIPercentDrivenInteractiveTransition?
    private var interactionInProgress = false
    private var shouldCompleteTransition = false
    
    // Used for canned end-of-stack animations
    private var isEndOfStack = false
    private var animator = UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.50)

    func addGestures(toViewController:UIViewController) {
        viewController = toViewController
        
        let leftEdgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action:
            #selector(handleLeftEdgeGesture(_:)))
        leftEdgeGesture.edges = .left
        leftEdgeGesture.delegate = self
        viewController?.view.addGestureRecognizer(leftEdgeGesture)
            
        let rightEdgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action:
            #selector(handleRightEdgeGesture(_:)))
        rightEdgeGesture.edges = .right
        rightEdgeGesture.delegate = self
        viewController?.view.addGestureRecognizer(rightEdgeGesture)
    }
    
    func performDefaultAnimation() {
        animator.addAnimations {
            self.viewController?.view.layer.transform = CATransform3DMakeTranslation(0.0, 0.0, 0.0)
        }
        animator.startAnimation()
    }
    
    @objc func handleLeftEdgeGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let screenWidth = UIScreen.main.bounds.width
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress =  (translation.x / screenWidth)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
        //print(progress)
        switch gestureRecognizer.state {
        case .began:
            viewController?.navigationController?.delegate = self
            interactionInProgress = true
            interactionController = UIPercentDrivenInteractiveTransition()
            // Kick off the standard pop view controller animation
            let vc = viewController?.navigationController?.popViewController(animated: true)
            if (vc == nil) {
                isEndOfStack = true
                viewController?.navigationController?.delegate = nil
            } else {
                isEndOfStack = false
            }
        case .changed:
            shouldCompleteTransition = progress > 0.5
            interactionController?.update(progress)
            if (isEndOfStack) {
                // Allow manual dragging up to 1/2 the screen width
                var transform: CATransform3D = CATransform3DIdentity
                viewController?.view.layer.anchorPointZ = -((viewController?.view.frame.size.width)! / 2)
                transform = CATransform3DIdentity
                transform.m34 = -1.0 / 1000
                transform = CATransform3DTranslate(transform, 0, 0, (viewController?.view.layer.anchorPointZ)!)
                viewController?.view.layer.transform = transform
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
    
    @objc func handleRightEdgeGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let screenWidth = UIScreen.main.bounds.width
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress = (translation.x / screenWidth) * -1
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
        //print(progress)
        
        switch gestureRecognizer.state {
        case .began:
            interactionInProgress = true
            interactionController = UIPercentDrivenInteractiveTransition()
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
        case .changed:
            shouldCompleteTransition = progress > 0.5
            interactionController?.update(progress)
            if (isEndOfStack) {
                // Allow manual dragging up to -1/2 the screen width
                var transform: CATransform3D = CATransform3DIdentity
                viewController?.view.layer.anchorPointZ = -((viewController?.view.frame.size.width)! / 2)
                transform = CATransform3DIdentity
                transform.m34 = -1.0 / 1000
                transform = CATransform3DTranslate(transform, 0, 0, (viewController?.view.layer.anchorPointZ)!)
                viewController?.view.layer.transform = transform
                viewController?.view.layer.transform = CATransform3DRotate((viewController?.view.layer.transform)!, ((CGFloat(Double.pi/4))*progress) * -1.0, 0, 1, 0)
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

extension EdgePanNavigationTransition: UIGestureRecognizerDelegate {
    
}

extension EdgePanNavigationTransition: UIViewControllerAnimatedTransitioning {
    
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
        
        // Reset the views
        toVC.view.layer.transform = CATransform3DIdentity
        toVC.view.layer.opacity = 1.0
        toVC.view.layer.anchorPointZ = 0
        
        fromVC.view.layer.transform = CATransform3DIdentity
        fromVC.view.layer.opacity = 1.0
        fromVC.view.layer.anchorPointZ = 0
        
        switch operation {
        case .push:
            
            // To view goes on top for push
            containerView.addSubview(fromVC.view)
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
                        fromVC.view.layer.transform = CATransform3DMakeTranslation(-screenWidth/3, 0.0, 0.0)
                        fromVC.view.layer.opacity = 0.5
                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                        toVC.view.layer.transform = CATransform3DMakeTranslation(0.0, 0.0, 0.0)
                    }
            },
                completion: { _ in
                    
                    // Reset the transforms
                    toVC.view.layer.transform = CATransform3DIdentity
                    toVC.view.layer.opacity = 1.0
                    toVC.view.layer.shadowOpacity = 0.0

                    fromVC.view.layer.transform = CATransform3DIdentity
                    fromVC.view.layer.opacity = 1.0
                    
                    // Gotta call this
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    
                    // Reset the navigationController delegate if they exist
                    // Necessary for subsequent expected nav controller behavior
                    fromVC.navigationController?.delegate = nil
                    toVC.navigationController?.delegate = nil
            })
            
        case .pop:
            
            // From view goes on top for pop
            containerView.addSubview(toVC.view)
            containerView.addSubview(fromVC.view)

            // Place the new view offscreen just off the left edge
            toVC.view.layer.transform = CATransform3DMakeTranslation(-screenWidth/2, 0.0, 0.0)
            toVC.view.layer.opacity = 0.5
            
            // Add a shadow to the view on top
            fromVC.view.layer.shadowColor = UIColor.black.cgColor
            fromVC.view.layer.shadowOpacity = 0.15
            fromVC.view.layer.shadowOffset = CGSize.zero
            fromVC.view.layer.shadowRadius = 10
            fromVC.view.layer.shadowPath = UIBezierPath(rect: toVC.view.bounds).cgPath

            UIView.animateKeyframes(
                withDuration: duration,
                delay: 0,
                options: .calculationModeLinear,
                animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                        fromVC.view.layer.transform = CATransform3DMakeTranslation(screenWidth, 0.0, 0.0)
                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                        toVC.view.layer.transform = CATransform3DMakeTranslation(0, 0.0, 0.0)
                        toVC.view.layer.opacity = 1.0
                    }
            },
                completion: { _ in
                    fromVC.view.layer.transform = CATransform3DIdentity
                    fromVC.view.layer.opacity = 1.0
                    fromVC.view.layer.shadowOpacity = 0.0

                    toVC.view.layer.transform = CATransform3DIdentity
                    toVC.view.layer.opacity = 1.0
                    
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

extension EdgePanNavigationTransition: UINavigationControllerDelegate {
    
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



