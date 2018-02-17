//
//  FifthViewController.swift
//  InteractiveViewControllerTransitions
//
//  Created by Justin Rhoades on 12.02.18.
//  Copyright © 2018 Justin Rhoades. All rights reserved.
//

import UIKit

class FifthViewController: UIViewController {
    
    var transition = PanCubeNavigationTransition()

    override func viewDidLoad() {
        super.viewDidLoad()
        transition.addGestures(toViewController:self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
