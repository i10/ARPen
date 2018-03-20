//
//  SettingsTableViewController.swift
//  ARPen
//
//  Created by Philipp Wacker on 06.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, UITextFieldDelegate  {

    var scene: PenScene!
    var userStudyRecordManager: UserStudyRecordManager!
    
    @IBOutlet weak var penSizeLabel: UILabel!
    @IBOutlet weak var penSizeSlider: UISlider!
    @IBOutlet weak var bluetoothDeviceTableViewCell: UITableViewCell!
    @IBOutlet weak var userIDTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.userIDTextField.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        //Setup UI Elements
        let currentPenSize = UserDefaults.standard.float(forKey: UserDefaultsKeys.penLength.rawValue) * 100
        self.penSizeSlider.value = currentPenSize
        self.penSizeLabel.text = "\(currentPenSize) cm"
        
        self.setCurrentBluetoothDeviceLabel()
        
        //if there is a currently active user ID set in the record manager, use this in the ID text field. Otherwise, use placeholder
        if let currentActiveUserID = self.userStudyRecordManager.currentActiveUserID {
            self.userIDTextField.text = String(currentActiveUserID)
        } else {
            self.userIDTextField.text = ""
            self.userIDTextField.placeholder = "Enter a number"
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Update the pen size label while the slider is dragged
    @IBAction func penSizeSliderChanged(_ sender: Any) {
        let roundedValueInCM = (self.penSizeSlider.value*10).rounded()/10
        
        self.penSizeLabel.text = "\(roundedValueInCM) cm"
        
    }
    // Store the final pen size in the user defaults and update the offset for the marker box
    @IBAction func penSizeSliderReleased(_ sender: Any) {
        let roundedValueInM = ((self.penSizeSlider.value*10).rounded()/10)/100
        
        UserDefaults.standard.set(roundedValueInM, forKey: UserDefaultsKeys.penLength.rawValue)
        let parent = self.scene.markerBox.parent
        self.scene.markerBox.removeFromParentNode()
        self.scene.markerBox = MarkerBox(length: Double(roundedValueInM))
        parent?.addChildNode(self.scene.markerBox)
    }
    
    @IBAction func clearSceneButtonPressed(_ sender: Any) {
        //remove all child nodes from drawing node
        self.scene.drawingNode.enumerateChildNodes {(node, pointer) in
            node.removeFromParentNode()
        }
    }
    
    @IBAction func shareAsSTLPressed(_ sender: Any) {
        let filePath = self.scene.share()
        let activityView = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
        self.present(activityView, animated: true, completion: nil)
    }
    
    @IBAction func disconnectDevicePressed(_ sender: Any) {
        UserDefaults.standard.set("", forKey: UserDefaultsKeys.arPenName.rawValue)
        setCurrentBluetoothDeviceLabel()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setCurrentBluetoothDeviceLabel() {
        var bluetoothTableViewText = "No Bluetooth device connected"
        if let currentBluetoothDevice = UserDefaults.standard.string(forKey: UserDefaultsKeys.arPenName.rawValue), !currentBluetoothDevice.isEmpty{
            bluetoothTableViewText = currentBluetoothDevice
        }
        self.bluetoothDeviceTableViewCell.textLabel?.text = bluetoothTableViewText
    }
    
    //ask the user Study Record Manager for the URL to a plist (only returned, if the creation of a plist was successfull). Use this URL to show the share dialog
    @IBAction func exportAsPlistButtonPressed(_ sender: Any) {
        guard let filePath = self.userStudyRecordManager.urlToPlist() else {
            print("Filepath was not created")
            return
        }
        let activityView = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
        self.present(activityView, animated: true, completion: nil)
    }
    
    //ask the user Study Record Manager for the URL to a CSV (only returned, if the creation of a CSV was successfull). Use this URL to show the share dialog
    @IBAction func exportAsCSVButtonPressed(_ sender: Any) {
//        let filePath = self.userStudyRecordManager.shareCSV()
//        let activityView = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
//        self.present(activityView, animated: true, completion: nil)
    }
    
    //show an alert warning of the deletion of all records. Only after confirmation, delete all records in the user study records manager.
    @IBAction func deleteAllRecordsButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Delete all Records?", message: "Should all records be deleted? This can not be undone.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: {action in
            self.userStudyRecordManager.deleteAllRecords()
            self.userIDTextField.text = ""
            })
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    //TextFieldDelegate Methods
    //taken from: https://stackoverflow.com/questions/26919854/how-can-i-declare-that-a-text-field-can-only-contain-an-integer
    //restrict possible inputs only to numbers. Other input will be ignored
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let invalidCharacters = CharacterSet(charactersIn: "0123456789").inverted
        return string.rangeOfCharacter(from: invalidCharacters, options: [], range: string.startIndex ..< string.endIndex) == nil
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //after return has been pressed, check if current text value is an int.
        guard let newText = textField.text, let newUserID = Int(newText) else {
            //otherwise, set placeholder text for text field
            textField.text = ""
            textField.placeholder = "Enter a number"
            return true
        }
        //set the currently active UserID to entered userID
        self.userStudyRecordManager.currentActiveUserID = newUserID
        
        textField.resignFirstResponder()
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //check if segue leads to the table view that displays the recorded user ids
        if segue.identifier == "showUserStudyUserIDs" {
            guard let destinationVC = segue.destination as? UserStudyIDListTableViewController else {
                return
            }
            //pass the reference to the record manager to the new VC
            destinationVC.userStudyRecordManager = self.userStudyRecordManager
        }
    }
    
}
