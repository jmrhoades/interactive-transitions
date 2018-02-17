//
//  ThirdViewController.swift
//  InteractiveViewControllerTransitions
//
//  Created by Justin Rhoades on 31.01.18.
//  Copyright © 2018 Justin Rhoades. All rights reserved.
//

import UIKit

class ThirdViewController: UIViewController {
    
    var transition =  EdgePanNavigationTransition()
    var transition2 = PinchScaleNavigationTransition()


    override func viewDidLoad() {
        super.viewDidLoad()
        transition.addGestures(toViewController:self)
        transition.nextStoryboardID = "FourthViewController"
        transition2.addGestures(toViewController:self)
        transition2.nextStoryboardID = "FourthViewController"
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

