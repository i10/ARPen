//
//  SettingsViewController.swift
//  ARPen
//
//  Created by Felix Wehnert on 01.02.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import UIKit
import Eureka
import CoreBluetooth

class SettingsViewController: FormViewController, CBCentralManagerDelegate {

    
    
    var scene: PenScene!
    var manager: CBCentralManager!
    var peripherals = Set<CBPeripheral>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.manager = CBCentralManager()
        self.manager.delegate = self
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissVC))
        self.navigationItem.title = "Einstellungen"
        
        form +++ Section("Allgemein")
            <<< SliderRow(){
                $0.title = "Länge des Stifts"
                $0.value = UserDefaults.standard.float(forKey: UserDefaultsKeys.penLength.rawValue) * 100
                $0.maximumValue = 20
                $0.minimumValue = 10
                $0.onChange({ (row) in
                    guard let rowValue = row.value else {
                        return
                    }
                    let value = Double(rowValue / 100.0) // convert to meter
                    
                    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.penLength.rawValue)
                    let parent = self.scene.markerBox.parent
                    self.scene.markerBox.removeFromParentNode()
                    self.scene.markerBox = MarkerBox(length: value)
                    parent?.addChildNode(self.scene.markerBox)
                })
            }
            <<< ButtonRow(){
                $0.title = "Szene als STL teilen"
                $0.onCellSelection({ (_, _) in
                    let filePath = (self.scene).share()
                    let view = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
                    self.present(view, animated: true, completion: nil)
                })
            } +++ Section("Bluetooth")
            <<< PushRow<String>() {
                $0.value = "Vorhandene Bluetoothgeräte"
                $0.selectorTitle = "Choose a lazy Emoji!"
                $0.tag = "Bluetooth"
                $0.options = ["No Bluetooth devices"]
            } <<< ButtonRow() {
                $0.title = "Verbindung trennen"
                $0.onCellSelection({ (_, _) in
                    
                })
        }
    }
    
    @objc func dismissVC() {
        self.manager.stopScan()
        self.dismiss(animated: true, completion: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.manager.scanForPeripherals(withServices: nil, options: nil)
        default:
            break
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripherals.insert(peripheral)
        let bluetoothRow: PushRow = self.form.rowBy(tag: "Bluetooth") as! PushRow<String>
        bluetoothRow.options = self.peripherals.map({$0.name ?? "No Name"})
        bluetoothRow.reload()
    }
}
