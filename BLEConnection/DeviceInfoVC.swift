//
//  ViewController.swift
//  BLEConnection
//
//  Created by Dawid on 09/05/2018.
//  Copyright © 2018 Dawid Bazan. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceInfoVC: UITableViewController {

    var bluetooth = BluetoothHandler.sharedInstance
    var selectedDevice: CBPeripheral!
    var deviceInfo: [String] = []
    
    override func viewWillAppear(_ animated: Bool) {
        
        navigationItem.title = selectedDevice.name
        bluetooth.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        bluetooth.delegate = nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceInfo.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = deviceInfo[indexPath.row]
        
        return cell!
    }
}

extension DeviceInfoVC: DBBluetoothDelegate {
    
    func bluetoothDidReceiveNotifyForCharacteristic(_ characteristic: CBCharacteristic) {
        
        if let data = characteristic.value {
            let dataString = String(data: data, encoding: String.Encoding.utf8)
            deviceInfo.append(dataString!)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}
