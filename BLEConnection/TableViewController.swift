//
//  TableViewController.swift
//  BLEConnection
//
//  Created by Dawid on 10/05/2018.
//  Copyright © 2018 Dawid Bazan. All rights reserved.
//

import UIKit
import CoreBluetooth


class TableViewController: UITableViewController {
    
    var bluetooth = BluetoothHandler.sharedInstance
    var discoveredPeripherals: [CBPeripheral] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetooth.delegate = self
        bluetooth.startScan()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        bluetooth.delegate = nil
    }
 
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
        return discoveredPeripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = discoveredPeripherals[indexPath.row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
    }
}

extension TableViewController: DBBluetoothDelegate {
    
    func bluetoothDidDiscoverPeripheral(_ peripheral: CBPeripheral) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
    }
}
