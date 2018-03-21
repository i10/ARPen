//
//  BluetoothDeviceListTableViewController.swift
//  ARPen
//
//  Created by Philipp Wacker on 07.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothDeviceListTableViewController: UITableViewController, CBCentralManagerDelegate {

    var manager: CBCentralManager!
    var peripheralsArray = Array<CBPeripheral>()
    var peripherals = Set<CBPeripheral>(){
        didSet{
            peripheralsArray = Array(peripherals)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.manager = CBCentralManager()
        self.manager.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.manager.stopScan()
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
        return self.peripheralsArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bluetoothDeviceCell", for: indexPath)

        let currentPeripheral = peripheralsArray[indexPath.row]
        
        cell.textLabel?.text = currentPeripheral.name
        cell.detailTextLabel?.text = currentPeripheral.identifier.uuidString

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let deviceName = tableView.cellForRow(at: indexPath)?.textLabel?.text {
            UserDefaults.standard.set(deviceName, forKey: UserDefaultsKeys.arPenName.rawValue)
        }
        self.navigationController?.popViewController(animated: true)
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
        self.tableView.reloadData()
    }
    
}
