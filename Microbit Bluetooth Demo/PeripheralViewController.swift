//
//  PeripheralViewController.swift
//  Microbit Bluetooth
//
//  Created by Aizat Omar on 3/6/18.
//  Copyright © 2018 Mosque Tech Challenge. All rights reserved.
//

import UIKit
import CoreBluetooth

// Based on Core Bluetooth Programming Guide
// Performing Common Central Role Tasks
// https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/PerformingCommonCentralRoleTasks/PerformingCommonCentralRoleTasks.html#//apple_ref/doc/uid/TP40013257-CH3-SW1

// 4. Discover service
// 5. Discover characteristics

final class PeripheralViewController: UIViewController {
    
    // MARK: Constants
    // IMPORTANT! UUIDs are obtained from the spec sheet
    // Please refer to spec sheet for most of the implementations being done here
    // https://lancaster-university.github.io/microbit-docs/resources/bluetooth/bluetooth_profile.html
    fileprivate let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    fileprivate let txUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    fileprivate let rxUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    // MARK: Variables
    internal var peripheral: CBPeripheral?
    fileprivate var service: CBService?
    fileprivate var txCharacteristic: CBCharacteristic?
    fileprivate var rxCharacteristic: CBCharacteristic?
    
    // MARK: - View controller functions
    override internal func viewDidLoad() {
        super.viewDidLoad()
        
        self.peripheral?.delegate = self
        
        // MARK: STEP 4: Discover services
        self.peripheral?.discoverServices(nil)
    }
}

// MARK: - IBActions
extension PeripheralViewController {
    @IBAction private func pressA() {
        if let characteristic = self.rxCharacteristic {
            let data = Data("A\n".utf8)
            self.peripheral?.writeValue(data,
                                        for: characteristic,
                                        type: .withoutResponse)
        }
    }
    
    @IBAction private func pressB() {
        if let characteristic = self.rxCharacteristic {
            let data = Data("B\n".utf8)
            self.peripheral?.writeValue(data,
                                        for: characteristic,
                                        type: .withoutResponse)
        }
    }
}

// MARK: Peripheral delegate
extension PeripheralViewController: CBPeripheralDelegate {
    internal func peripheral(_ peripheral: CBPeripheral,
                             didDiscoverServices error: Error?) {
        if let error = error {
            #if DEBUG
            print("Error: \(error.localizedDescription)")
            #endif
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                if service.uuid == self.serviceUUID {
                    // Update service
                    self.service = service
                    
                    // MARK: STEP 5: Discover characteristics
                    self.peripheral?.discoverCharacteristics([self.txUUID, self.rxUUID],
                                                             for: service)
                    break
                }
            }
        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral,
                             didDiscoverCharacteristicsFor service: CBService,
                             error: Error?) {
        if let error = error {
            #if DEBUG
            print("Error: \(error.localizedDescription)")
            #endif
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                // Update characteristics
                if characteristic.uuid == self.txUUID {
                    self.txCharacteristic = characteristic
                    
                    // Set notify value
                    peripheral.setNotifyValue(true,
                                              for: characteristic)
                }
                
                if characteristic.uuid == self.rxUUID {
                    self.rxCharacteristic = characteristic
                }
            }
        }
    }
    
    internal func peripheral(_ peripheral: CBPeripheral,
                             didUpdateValueFor characteristic: CBCharacteristic,
                             error: Error?) {
        if let error = error {
            #if DEBUG
            print("Error: \(error.localizedDescription)")
            #endif
            return
        }
        
        if characteristic.uuid == self.txUUID {
            if let data = characteristic.value,
                let stringValue = String(data: data,
                                         encoding: .utf8) {
                print(stringValue)
            }
        }
    }
}
