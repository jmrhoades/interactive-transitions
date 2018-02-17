//
//  FirstViewController.swift
//  InteractiveViewControllerTransitions
//
//  Created by Justin Rhoades on 30.01.18.
//  Copyright © 2018 Justin Rhoades. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    
    // This is the class that handles all the transition delegates and protocols
    // Try changing the class to one of these
    // EdgePanNavigationTransition()
    // PinchScaleNavigationTransition()
    // PanCubeNavigationTransition()
    var transition = PanCubeNavigationTransition()

    override func viewDidLoad() {
        super.viewDidLoad()
        transition.addGestures(toViewController:self)
        transition.nextStoryboardID = "SecondViewController"
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // This needs to be here for IB to be able to do the unwind thing
    @IBAction func unwindToFirstViewController(for segue:UIStoryboardSegue) { }


}

