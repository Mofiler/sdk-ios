//
//  BTScanner.swift
//  Mofiler
//
//  Created by Bryan Tafel on 7/13/17.
//  Copyright © 2017 MobileTonic. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Implement this to receive notifications about beacons.
protocol BluetoothScannerDelegate {
    func didFindPeripheral(_ bluetoothScanner: BluetoothScanner, scannedPeripheral: ScannedPeripheral)
    func didLosePeripheral(_ bluetoothScanner: BluetoothScanner, scannedPeripheral: ScannedPeripheral)
    func didUpdatePeripheral(_ bluetoothScanner: BluetoothScanner, scannedPeripheral: ScannedPeripheral)
}

class BluetoothScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var delegate: BluetoothScannerDelegate?
    var blueToothReady = false
    fileprivate var centralManager: CBCentralManager!
    var scannedPeripherals: [ScannedPeripheral] = []

    override init() {
        super.init()
    
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.centralManager.delegate = self
    }

///
/// Start scanning. If Core Bluetooth isn't ready for us just yet, then waits and THEN starts
/// scanning.
///
    func startScanning() {

        if blueToothReady {
            //Start scanning for devices
            discoverDevices()
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            print("CoreBluetooth BLE hardware is powered off")
        case .poweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready")
            blueToothReady = true;
            
        default: break
        }
    }
    
    func discoverDevices() {
        print("Discovering devices")
        //Scan for peripherals
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    //Central Manager method called every time a device is scanned. Manage them with an array to add new ones and update data on the old ones.
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var namee = "N/A"
        if(peripheral.name != nil){
            namee = peripheral.name!
        }
        //        NSLog("\(namee) - \(RSSI)")
        
        //RSSI 127 is an error code which indicates the data received is corrupted. Cannot be treated as RSSI.
        if(RSSI == 127){
            return
        }
        
        var contains = false
        if(scannedPeripherals.count>0){
            for i in 0...(scannedPeripherals.count-1){
                if(i<scannedPeripherals.count && peripheral.identifier.uuidString == scannedPeripherals[i].uuid){
                    scannedPeripherals[i] = ScannedPeripheral(peri: peripheral, name: namee, uuid: peripheral.identifier.uuidString, rssi: RSSI.intValue)
                    contains = true
                    self.delegate?.didUpdatePeripheral(self, scannedPeripheral: scannedPeripherals[i])
                    break
                }
            }
        }
        if(!contains){
            NSLog("new device found \(namee) - \(RSSI)")
            let sp = ScannedPeripheral(peri:peripheral, name: namee, uuid: peripheral.identifier.uuidString, rssi: RSSI.intValue)
            
            scannedPeripherals.append(sp)
            
            self.delegate?.didFindPeripheral(self, scannedPeripheral: sp)
            
            //            if (RSSI.intValue > -15 || RSSI.intValue < -35) {
            // With those RSSI values, probably not an iBeacon.
            //            } else {
            // Try to obtain beacon information
//            if (namee == "Kontakt"){
                centralManager.connect(peripheral, options: nil);
//            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self;
        peripheral.discoverServices(nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        // discoveredPeripheral = nil
        if(scannedPeripherals.count>0){
            for i in 0...(scannedPeripherals.count-1){
                if(i<scannedPeripherals.count && peripheral.identifier.uuidString == scannedPeripherals[i].uuid){
                    self.delegate?.didLosePeripheral(self, scannedPeripheral: scannedPeripherals[i])
                    break
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard error == nil else {
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard error == nil else {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                //                print("characteristic.uuid.uuidString \(characteristic.uuid.uuidString)")
                //                if characteristic.uuid.uuidString == "2A24" { // UUID
                peripheral.readValue(for: characteristic)
                //                }
            }
        }
    }
    var value = Data();
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            return;
        }
        
        let data = characteristic.value
        let dataString = String(data: data!, encoding: String.Encoding.utf8)
        print("************\(characteristic.uuid.uuidString) \(dataString)")
        print("char \(characteristic)")
        print("************")
        
        //print("characteristic \(characteristic) \(characteristic.value?.hexString)")
        
        //        if value == characteristic.value! {
        // value will be a Data object with bits that represent the UUID you're looking for.
        //            print("Found beacon UUID: \(value.hexString)")
        // This is where you can start the CLBeaconRegion and start monitoring it, or just get the value you need.
        //        }
    }

    
    
}
//Beacon class which defines the structure of the data we need.
class ScannedPeripheral {
    
    var mPeri: CBPeripheral
    var name: String
    var uuid: String
    var rssi: Int
    
    
    init(peri: CBPeripheral, name: String, uuid: String, rssi: Int) {
        self.mPeri = peri
        self.name = name
        self.uuid = uuid
        self.rssi = rssi
    }
}
