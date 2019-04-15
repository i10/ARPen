//
//  ARPenTypeSelectionViewController.swift
//  ARPen
//
//  Created by Philipp Wacker on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import UIKit

class ARPenTypeSelectionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func arPenTypeButtonPressed(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            UserDefaults.standard.set(ARPenType.fullyFunctional.rawValue, forKey: UserDefaultsKeys.arPenType.rawValue)
        case 1:
            UserDefaults.standard.set(ARPenType.penWithoutBluetooth.rawValue, forKey: UserDefaultsKeys.arPenType.rawValue)
        case 2:
            UserDefaults.standard.set(ARPenType.cardboardDemo.rawValue, forKey: UserDefaultsKeys.arPenType.rawValue)
        default:
            UserDefaults.standard.set(ARPenType.notSelected.rawValue, forKey: UserDefaultsKeys.arPenType.rawValue)
        }
        
        self.performSegue(withIdentifier: "showARPenView", sender: self)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
