//
//  ViewController.swift
//  CustomTransitionAnimator
//
//  Created by Broccoli on 15/11/24.
//  Copyright © 2015年 Broccoli. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var animator: UIViewControllerTransitioningDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
   
    @IBAction func btnClicked(sender: AnyObject) {
        
        let modalVC = TestViewController()
        modalVC.modalPresentationStyle = UIModalPresentationStyle.Custom
        modalVC.view.backgroundColor = UIColor.orangeColor()
        
        animator = CustomTransitionAnimator(modal: modalVC)
        modalVC.transitioningDelegate = animator
        self.presentViewController(modalVC, animated: true, completion: nil)
    }
}

