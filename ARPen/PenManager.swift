//
//  ARPenManager.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import CoreBluetooth

/**
 PenManager 
 */
protocol PenManagerDelegate {
    func button(_ button: Button, pressed: Bool)
    func connect(successfully: Bool)
}

/**
 The PenManager manages the bluetooth connection to the bluetooth chip of the hardware ARPen.
 */
class PenManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private let centralManager: CBCentralManager
    private let serviceUUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
    private var peripheral: CBPeripheral?
    var delegate: PenManagerDelegate?
    
    override init() {
        centralManager = CBCentralManager()
        super.init()
        centralManager.delegate = self
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        if peripheral.name == "BLE Serial" {
            self.centralManager.stopScan()
            self.peripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegate?.connect(successfully: true)
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.delegate?.connect(successfully: false)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for service in peripheral.services! {
            for characteristic in service.characteristics! {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else {
            print("noData")
            return
        }
        
        let string = String(data: data, encoding: .utf8)!
        let array = string.split(separator: ":")
        
        guard array.count == 2 else {
            print("wrongData")
            return
        }
        
        switch String(describing: array.first!) {
        case "B1":
            self.delegate?.button(.Button1, pressed: array.last! == "DOWN")
        case "B2":
            self.delegate?.button(.Button2, pressed: array.last! == "DOWN")
        case "B3":
            self.delegate?.button(.Button3, pressed: array.last! == "DOWN")
        default:
            print("Unkown Button pressed")
        }
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        default:
            break
        }
    }
    
    deinit {
        if let peripheral = self.peripheral {
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    
}
