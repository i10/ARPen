//
//  ModelListViewController.swift
//  ARPen
//
//  Created by René Schäfer on 14.05.21.
//  Copyright © 2021 RWTH Aachen. All rights reserved.
//

import UIKit

class ModelListViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ARPenModelKeys.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ARPenModelCell", for: indexPath)
        cell.textLabel?.text = ARPenModelKeys.allCases[indexPath.row].string

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let model = tableView.cellForRow(at: indexPath)?.textLabel?.text {
            for modelKey in ARPenModelKeys.allCases {
                if(model == modelKey.string) {
                    UserDefaults.standard.set(modelKey.rawValue, forKey: UserDefaultsKeys.arPenModel.rawValue)
                    break
                }
            }
        }
        self.navigationController?.popViewController(animated: true)
    }
}
