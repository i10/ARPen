//
//  SettingsTableViewController.swift
//  ARPen
//
//  Created by Philipp Wacker on 06.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController  {

    var scene: PenScene!
    
    @IBOutlet weak var penSizeLabel: UILabel!
    @IBOutlet weak var penSizeSlider: UISlider!
    @IBOutlet weak var bluetoothDeviceTableViewCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        //Setup UI Elements
        let currentPenSize = UserDefaults.standard.float(forKey: UserDefaultsKeys.penLength.rawValue) * 100
        self.penSizeSlider.value = currentPenSize
        self.penSizeLabel.text = "\(currentPenSize) cm"
        
        self.setCurrentBluetoothDeviceLabel()
        
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

}
