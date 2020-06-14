//
//  UserStudyIDListTableViewController.swift
//  ARPen
//
//  Created by Philipp Wacker on 13.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import UIKit

class UserStudyIDListTableViewController: UITableViewController {

    //reference to the study record manager
    var userStudyRecordManager : UserStudyRecordManager! {
        didSet {
            //if the study record manager is set, the userStudyKeys property should be updated to have the sorted keys of the userStudyData dictionary --> sorted list of userIDs
            self.userStudyKeys = self.userStudyRecordManager.getSortedListOfUserIDs()
        }
    }
    var userStudyKeys : [Int]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //the tableVC should display the edit button
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        //only one section displaying the userIDs
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //the number of rows equals the number of IDs --> number of userStudyKeys
        return self.userStudyKeys.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userIDCell", for: indexPath)

        //the title of the cell is the key at the indexPath.row in the userStudyKeys Array
        cell.textLabel?.text = String(self.userStudyKeys![indexPath.row])
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        //During editing, the delete button should be displayed for each row
        return .delete
    }


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let removedKey = self.userStudyKeys.remove(at: indexPath.row)
            _ = self.userStudyRecordManager.deleteRecords(forID: removedKey)
            
            
            //if the removed ID is the current active one, reset the currentActiveUserID for the recordManager
            if removedKey == self.userStudyRecordManager.currentActiveUserID {
                self.userStudyRecordManager.currentActiveUserID = nil
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }


    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // check if the next VC is showing the user study records
        if segue.identifier == "showUserStudyUserRecords" {
            //cast destination VC and extract userID from the cell selected (userIDOfSenderCell)
            guard let destinationVC = segue.destination as? UserStudyRecordsListTableViewController, let senderCell = sender as? UITableViewCell, let textOfSenderCell = senderCell.textLabel?.text, let userIDOfSenderCell = Int(textOfSenderCell) else {
                return
            }
            //pass reference to user study record manager & set the userID property of receiver
            destinationVC.userStudyRecordsManager = self.userStudyRecordManager
            destinationVC.userID = userIDOfSenderCell
        }
    }
    
}
