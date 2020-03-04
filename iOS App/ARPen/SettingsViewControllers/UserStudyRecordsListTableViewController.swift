//
//  UserStudyRecordsListTableViewController.swift
//  ARPen
//
//  Created by Philipp Wacker on 13.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import UIKit

class UserStudyRecordsListTableViewController: UITableViewController, UINavigationControllerDelegate {

    var userStudyRecordsManager : UserStudyRecordManager!
    var userID : Int!
    var userRecords : [UserStudyRecord]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set as the delegate of the navigation controller to detect back button press
        self.navigationController?.delegate = self
        
        // edit button should be shown
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //set userRecords to record array from records manager with the passed userID
        self.userRecords = self.userStudyRecordsManager.getRecords(forID: userID)
        
        tableView.reloadData()
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
        //check if userRecords is set
        guard let numberOfUserRecords = self.userRecords?.count else {
            //otherwise return 0 (no rows to display)
            return 0
        }
        
        return numberOfUserRecords
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userRecordCell", for: indexPath)

        //if the userRecords are not set, return a general cell (should not happen)
        guard let userRecords = userRecords else {
            return cell
        }

        //specify properties of the cell by extracting information from the matching record
        let currentRecord = userRecords[indexPath.row]
        //get and format the creation date
        let date = currentRecord.creationTime
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let dateString = dateFormatter.string(from: date)
        cell.detailTextLabel?.text = dateString
        //the main text of the cell is the identifier of the record
        cell.textLabel?.text = currentRecord.identifier
        
        return cell
    }
    

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        //During editing, the delete button should be displayed for each row
        return .delete
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source & update the userStudyRecordsManager
            self.userStudyRecordsManager.deleteRecord(atPosition: indexPath.row, forID: self.userID)
            userRecords?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

}
