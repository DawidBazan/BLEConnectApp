//
//  BluetoothHandler.swift
//  BLEConnection
//
//  Created by Dawid on 02/03/2019.
//  Copyright © 2019 Dawid. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc protocol DBBluetoothDelegate {
    @objc optional func bluetoothDidPowerUp(_ bluetooth: BluetoothHandler)
    @objc optional func bluetoothDidBecomeReady(_ peripheral: CBPeripheral)
    @objc optional func bluetoothDidDiscoverPeripheral(_ peripheral:CBPeripheral)
    @objc optional func bluetoothDidConnect(_ peripheral: CBPeripheral)
    @objc optional func bluetoothDidDiscoverPeripheralInfo(_ peripheral: CBPeripheral)
    @objc optional func bluetoothDidDiscoverCharacteristic(_ characteristic:CBCharacteristic)
    @objc optional func bluetoothDidReceiveNotifyForCharacteristic(_ characteristic:CBCharacteristic)
    @objc optional func bluetoothDidDisconnect(_ peripheral: CBPeripheral)
}

class BluetoothHandler: NSObject {
    
    weak var delegate: DBBluetoothDelegate?
    var centralManagerQueue: DispatchQueue!
    var centralManager: CBCentralManager!
    
    let infoServiceUUID = "180A"
    var infoChars: [CBCharacteristic] = []
    
    static let sharedInstance: BluetoothHandler = {
        let instance = BluetoothHandler()
        return instance
    }()
    
    override init() {
        super.init()
   
        self.centralManagerQueue = DispatchQueue(label: "com.bluetooth.centralManagerQueue", attributes: [])
        self.centralManager = CBCentralManager(delegate: self, queue: self.centralManagerQueue)
    }

}

//// --------------------------------------------------------------------------------

// MARK: - Bluetooth Delegates


extension BluetoothHandler: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //// --------------------------------------------------------------------------------
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            print("Bluetooth powered on")
            break
        case .poweredOff:
            print("Bluetooth powered off")
            break
            
        default:
            print("central.state: ", central.state)
            break
        }
        self.delegate?.bluetoothDidPowerUp?(self)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if peripheral.name != nil {
        delegate?.bluetoothDidDiscoverPeripheral?(peripheral)
        }
 
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "default") \(peripheral.identifier.uuidString)")
        
        peripheral.discoverServices(nil)
        delegate?.bluetoothDidConnect?(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral");
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("\(peripheral.name!) Disconnected")
        
        peripheral.delegate = nil
        
        delegate?.bluetoothDidDisconnect?(peripheral)
    }
    
    // --------------------------------------------------------------------------------
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Discovered services")
        
        if let services = peripheral.services {
            for service: CBService in (services as Array) {
                if service.uuid.uuidString == infoServiceUUID {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Discovered characteristics for \(service.description)")
        
        
        for characteristic in service.characteristics! {
           
            peripheral.setNotifyValue(true, for: characteristic)
            peripheral.readValue(for: characteristic)
            delegate?.bluetoothDidDiscoverCharacteristic?(characteristic)
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        
        delegate?.bluetoothDidBecomeReady?(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if (characteristic.value == nil) { return }
        
        delegate?.bluetoothDidReceiveNotifyForCharacteristic?(characteristic)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            print("write sucessful")
        }
    }
    
    // --------------------------------------------------------------------------------
    
    // MARK: - Bluetooth functions
    
    func startScan() {
        print("scanning in progress")
        
        switch self.centralManager.state {
        case .poweredOn:
            let scanOptions = [ CBCentralManagerScanOptionAllowDuplicatesKey : false ]
           
            self.centralManager.scanForPeripherals(withServices: nil, options: scanOptions)
        default:
            break;
        }
    }
    
    func connectDevice(device: CBPeripheral) {
        
        if device.state != .connected {
            device.delegate = self
            let peripipheralOpts = [ CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey: true ]
            self.centralManager.connect(device, options: peripipheralOpts)
        }
    }
    
    func disconnectPeripheral(peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func sendValue(value: String, to peripheral: CBPeripheral) {
        
        let char = infoChars[0] //specify a char that allows writes. used info char as example but it's actually a read only.
        
        if let data = value.data(using: String.Encoding.utf8) {
            print("writing value to: ", char.uuid.uuidString)
            peripheral.writeValue(data, for: char, type: .withResponse)
            return
        }
    }
}
