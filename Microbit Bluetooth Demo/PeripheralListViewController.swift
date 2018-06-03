//
//  PeripheralListViewController.swift
//  Microbit Bluetooth
//
//  Created by Aizat Omar on 1/6/18.
//  Copyright © 2018 Mosque Tech Challenge. All rights reserved.
//

import UIKit
import CoreBluetooth

// Based on Core Bluetooth Programming Guide
// Performing Common Central Role Tasks
// https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/PerformingCommonCentralRoleTasks/PerformingCommonCentralRoleTasks.html#//apple_ref/doc/uid/TP40013257-CH3-SW1

// Steps for central manager:
// 1. Initialize central manager
// 2. Scan to discover peripheral
// 3. Connect to peripheral

final class PeripheralListViewController: UIViewController {
    
    // MARK: Constants
    private let segueIdentifier = "PeripheralListToPeripheral"
    
    // MARK: Variables
    fileprivate var centralManager: CBCentralManager?
    fileprivate var discoveredPeripherals: [CBPeripheral] = []
    fileprivate var connectedPeripheral: CBPeripheral?
    
    // MARK: IBOutlets
    @IBOutlet weak private var scanButton: UIBarButtonItem!
    @IBOutlet weak private var tableView: UITableView!
    
    // MARK: - View controller functions
    override internal func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: STEP 1: Initialize central manager
        self.centralManager = CBCentralManager(delegate: self,
                                               queue: nil,
                                               options: nil)
    }
    
    override internal func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Cancel any existing peripheral connection
        if let peripheral = self.connectedPeripheral {
            self.centralManager!.cancelPeripheralConnection(peripheral)
            self.connectedPeripheral = nil
        }
    }
    
    override internal func prepare(for segue: UIStoryboardSegue,
                                   sender: Any?) {
        if segue.identifier == self.segueIdentifier {
            let peripheralViewController = segue.destination as! PeripheralViewController
            peripheralViewController.peripheral = self.connectedPeripheral
        }
    }
    
}

// MARK: - Private functions
extension PeripheralListViewController {
    // Simple function to start scanning for peripherals
    fileprivate func startScan() {
        if self.centralManager!.state == .poweredOn {
            self.centralManager!.scanForPeripherals(withServices: nil,
                                                    options: nil)
        }
    }
    
    // Simple function to stop scanning for peripherals
    fileprivate func stopScan() {
        if self.centralManager!.state == .poweredOn {
            self.centralManager!.stopScan()
            self.scanButton.title = "Scan"
        }
    }
    
    
    // Simple function to show alert when Bluetooth is not powered on
    fileprivate func showPowerOffAlert() {
        let alert = UIAlertController(title: "Error",
                                      message: "Bluetooth is not powered on",
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK",
                                   style: .default,
                                   handler: nil)
        alert.addAction(action)
        self.present(alert,
                     animated: true,
                     completion: nil)
    }
}

// MARK: - IBActions
extension PeripheralListViewController {
    @IBAction private func pressScan() {
        if self.centralManager!.state == .poweredOn {
            if self.centralManager!.isScanning {
                self.stopScan()
            } else {
                // MARK: STEP 2: Start scanning
                self.startScan()
            }
        } else {
            self.showPowerOffAlert()
        }
    }
}

// MARK: - Central manager delegate
extension PeripheralListViewController: CBCentralManagerDelegate {
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Stop scanning whenever state is being updated
        self.stopScan()
    }
    
    internal func centralManager(_ central: CBCentralManager,
                                 didDiscover peripheral: CBPeripheral,
                                 advertisementData: [String : Any],
                                 rssi RSSI: NSNumber) {
        // Ignore peripherals with no name
        guard let name = peripheral.name else {
            return
        }
        
        if name == "" {
            return
        }
        
        // Get unique peripheral and sort in increasing alphabetical order
        var set: Set<CBPeripheral> = Set(self.discoveredPeripherals)
        set.insert(peripheral)
        self.discoveredPeripherals = set.sorted(by: { $0.name! < $1.name! })
        self.tableView.reloadData()
    }
    
    internal func centralManager(_ central: CBCentralManager,
                                 didConnect peripheral: CBPeripheral) {
        #if DEBUG
        print("Peripheral connected")
        #endif
        
        // Update connected peripheral
        self.connectedPeripheral = peripheral
        
        self.performSegue(withIdentifier: self.segueIdentifier,
                          sender: nil)
    }
    
    internal func centralManager(_ central: CBCentralManager,
                                 didDisconnectPeripheral peripheral: CBPeripheral,
                                 error: Error?) {
        #if DEBUG
        print("Peripheral disconnected")
        #endif
        if let error = error {
            #if DEBUG
            print("Error: \(error.localizedDescription)")
            #endif
        }
        
        // Update connected peripheral
        self.connectedPeripheral = nil
    }
}

// MARK: - Table view data source
extension PeripheralListViewController: UITableViewDataSource {
    internal func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return self.discoveredPeripherals.count
    }
    
    internal func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralListTableViewCell",
                                                 for: indexPath)
        
        let peripheral = self.discoveredPeripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name
        
        return cell
    }
}

// MARK: - Table view delegate
extension PeripheralListViewController: UITableViewDelegate {
    internal func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        if self.centralManager!.state != .poweredOn {
            self.showPowerOffAlert()
            return
        }
        
        // MARK: STEP 3: Connect to peripheral
        self.stopScan()
        let peripheral = self.discoveredPeripherals[indexPath.row]
        self.centralManager!.connect(peripheral,
                                     options: nil)
    }
}
