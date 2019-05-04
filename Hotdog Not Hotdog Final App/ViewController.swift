//
//  ViewController.swift
//  Hotdog Not Hotdog Final App
//
//  Created by Tom Kotopoulos
//  Copyright © 2019 Tom Kotopoulos. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func unwindToMainVC(segue:UIStoryboardSegue) {
        
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toHotdogSegue"{
            let desinationVC = segue.destination as! ImageClassificationViewController
            desinationVC.activeModel = HotdogClassifier().model
            desinationVC.modelName = "HotDog"
        } else if segue.identifier == "toBostonSports" {
            let desinationVC = segue.destination as! ImageClassificationViewController
            desinationVC.activeModel = Boston_Sports_Logos_1().model
            desinationVC.modelName = "Boston Sports"
        }
    }
    
}

