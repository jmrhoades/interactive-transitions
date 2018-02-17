//
//  SecondViewController.swift
//  InteractiveViewControllerTransitions
//
//  Created by Justin Rhoades on 30.01.18.
//  Copyright © 2018 Justin Rhoades. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    
    var transition = EdgePanNavigationTransition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        transition.addGestures(toViewController:self)
        transition.nextStoryboardID = "ThirdViewController"
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
   
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}


