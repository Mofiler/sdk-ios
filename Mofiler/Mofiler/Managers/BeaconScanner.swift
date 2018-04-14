// Copyright 2015-2016 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import CoreBluetooth
import CoreLocation

///
/// BeaconScannerDelegate
///
/// Implement this to receive notifications about beacons.
protocol BeaconScannerDelegate {
    func didFindBeacon(_ beaconScanner: BeaconScanner, beaconInfo: BeaconInfo)
    func didLoseBeacon(_ beaconScanner: BeaconScanner, beaconInfo: BeaconInfo)
    func didUpdateBeacon(_ beaconScanner: BeaconScanner, beaconInfo: BeaconInfo)
    func didObserveURLBeacon(_ beaconScanner: BeaconScanner, URL: URL, RSSI: Int)

    func didFindiBeacon(_ beaconScanner: BeaconScanner, iBeaconInfo: iBeaconInfo)
    func didLoseiBeacon(_ beaconScanner: BeaconScanner, iBeaconInfo: iBeaconInfo)
    func didUpdateiBeacon(_ beaconScanner: BeaconScanner, iBeaconInfo: iBeaconInfo)
}

///
/// BeaconScanner
///
/// Scans for Eddystone compliant beacons using Core Bluetooth. To receive notifications of any
/// sighted beacons, be sure to implement BeaconScannerDelegate and set that on the scanner.
///
class BeaconScanner: NSObject, CBCentralManagerDelegate, CLLocationManagerDelegate {
    
    var delegate: BeaconScannerDelegate?
//    var locationManager: CLLocationManager?
    let locationManager = CLLocationManager()
    ///
    /// How long we should go without a beacon sighting before considering it "lost". In seconds.
    ///
    var onLostTimeout: Double = 15.0
    
    fileprivate var centralManager: CBCentralManager!
    fileprivate let beaconOperationsQueue: DispatchQueue =
        DispatchQueue(label: "beacon_operations_queue", attributes: [])
    fileprivate var shouldBeScanning: Bool = false
    
    fileprivate var seenEddystoneCache = [String : [String : AnyObject]]()
    fileprivate var deviceIDCache = [UUID : Data]()
    
    var beaconList = [(CLBeaconRegion, CLBeacon)]()
    var beaconsToRange = [CLBeaconRegion]()

    
    override init() {
        super.init()
        
        self.centralManager = CBCentralManager(delegate: self, queue: self.beaconOperationsQueue)
        self.centralManager.delegate = self
    }
    
    ///
    /// Start scanning. If Core Bluetooth isn't ready for us just yet, then waits and THEN starts
    /// scanning.
    ///
    func startScanning() {
        self.beaconOperationsQueue.async {
            self.startScanningSynchronized()
        }
        
        
        //TODO bring list from server
        let beaconRegions = [
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "f7826da6-4fa2-4e98-8024-bc5b71e0893e")! as UUID, identifier: "Kontakt"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")! as UUID, identifier: "Estimote"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "E2C56DB5-dFFB-48D2-B060-D0F5A71096E0")! as UUID, identifier: "Apple AirLocate"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "74278BDA-B644-4520-8F0C-720EAF059935")! as UUID, identifier: "Apple AirLocate1"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")! as UUID, identifier: "Apple AirLocate2"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "EBEFD083-70A2-47C8-9837-E7B5634DF524")! as UUID, identifier: "Avvel International"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "E6BF275E-0BB3-43E5-BF88-517F13A5A162")! as UUID, identifier: "BeaconGo Portable"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "F6322B94-D58A-F34E-B1A5-17C69CFBE32E")! as UUID, identifier: "BeaconGo USB"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "F0018B9B-7509-4C31-A905-1A27D39C003C")! as UUID, identifier: "Beacon Inside"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "ACFD065E-C3C0-11E3-9BBE-1A514932AC01")! as UUID, identifier: "BlueUp Default"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "74278bda-b644-4520-8f0c-720eaf059935")! as UUID, identifier: "Glimworm Beacons"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "8AEFB031-6C32-486F-825B-E26FA193487D")! as UUID, identifier: "KST Particle"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "52414449-5553-4E45-5457-4F524B53434F")! as UUID, identifier: "Radius Network"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6")! as UUID, identifier: "Radius Network1"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "73676723-7400-0000-FFFF-0000FFFF0000")! as UUID, identifier: "Sensorberg SB-0"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "73676723-7400-0000-FFFF-0000FFFF0001")! as UUID, identifier: "Sensorberg SB-1"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "73676723-7400-0000-FFFF-0000FFFF0002")! as UUID, identifier: "Sensorberg SB-2"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "73676723-7400-0000-FFFF-0000FFFF0003")! as UUID, identifier: "Sensorberg SB-3"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "73676723-7400-0000-FFFF-0000FFFF0004")! as UUID, identifier: "Sensorberg SB-4"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "73676723-7400-0000-FFFF-0000FFFF0005")! as UUID, identifier: "Sensorberg SB-5"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "73676723-7400-0000-FFFF-0000FFFF0006")! as UUID, identifier: "Sensorberg SB-6"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "73676723-7400-0000-FFFF-0000FFFF0007")! as UUID, identifier: "Sensorberg SB-7"),
            CLBeaconRegion(proximityUUID: NSUUID(uuidString: "92AB49BE-4127-42F4-B532-90FAF1E26491")! as UUID, identifier: "TwoCanoes")
        ]
        
        if beaconRegions != nil {
            beaconRegions.forEach{region in
                region.notifyEntryStateOnDisplay  = true
                region.notifyOnEntry = true
                region.notifyOnExit = true
                print("Starting to scan for iBeacon region \(region.proximityUUID.uuidString)")
                locationManager.delegate = self
                locationManager.startMonitoring(for: region)
                locationManager.startRangingBeacons(in: region)
            }
        }
    }
    
    ///
    /// Stops scanning for Eddystone beacons.
    ///
    func stopScanning() {
        self.centralManager.stopScan()
    }
    
    // BEACON REGION
    func locationManager(_ manager: CLLocationManager,
                         didEnterRegion region: CLRegion) {
        if region is CLBeaconRegion {
            // Start ranging only if the feature is available.
            if CLLocationManager.isRangingAvailable() {
                manager.startRangingBeacons(in: region as! CLBeaconRegion)
                
                // Store the beacon so that ranging can be stopped on demand.
                beaconsToRange.append(region as! CLBeaconRegion)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // 1
//        var outputText = "Ranged beacons count: \(beacons.count)\n\n"
//        beacons.forEach { beacon in
//            outputText += beacon.description
//            outputText += "\n\n"
//        }
//        NSLog("%@", outputText)
        
        // 2
        beacons.forEach { beacon in
            let ibeacon = iBeaconInfo(beacon)
            if let index = beaconList.index(where: { $0.1.proximityUUID.uuidString == beacon.proximityUUID.uuidString && $0.1.major == beacon.major && $0.1.minor == beacon.minor }) {
                beaconList[index] = (region, beacon)
                self.delegate?.didUpdateiBeacon(self, iBeaconInfo: ibeacon)
            } else {
                beaconList.append((region, beacon))
                self.delegate?.didFindiBeacon(self, iBeaconInfo: ibeacon)
            }
        }
        
    }
    // END BEACON REGION

    ///
    /// MARK - private methods and delegate callbacks
    ///
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && self.shouldBeScanning {
            self.startScanningSynchronized();
        }
    }
    
    ///
    /// Core Bluetooth CBCentralManager callback when we discover a beacon. We're not super
    /// interested in any error situations at this point in time.
    ///
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey]
            as? [AnyHashable: Any] {
            var eft: BeaconInfo.EddystoneFrameType
            eft = BeaconInfo.frameTypeForFrame(serviceData)
            
            // If it's a telemetry frame, stash it away and we'll send it along with the next regular
            // frame we see. Otherwise, process the UID frame.
            if eft == BeaconInfo.EddystoneFrameType.telemetryFrameType {
                deviceIDCache[peripheral.identifier] = BeaconInfo.telemetryDataForFrame(serviceData)
            } else if eft == BeaconInfo.EddystoneFrameType.uidFrameType
                || eft == BeaconInfo.EddystoneFrameType.eidFrameType {
                let telemetry = self.deviceIDCache[peripheral.identifier]
                let serviceUUID = CBUUID(string: "FEAA")
                let _RSSI: Int = RSSI.intValue
                
                if let
                    beaconServiceData = serviceData[serviceUUID] as? Data,
                    let beaconInfo =
                    (eft == BeaconInfo.EddystoneFrameType.uidFrameType
                        ? BeaconInfo.beaconInfoForUIDFrameData(beaconServiceData, telemetry: telemetry,
                                                               RSSI: _RSSI)
                        : BeaconInfo.beaconInfoForEIDFrameData(beaconServiceData, telemetry: telemetry,
                                                               RSSI: _RSSI)) {
                    
                    // NOTE: At this point you can choose whether to keep or get rid of the telemetry
                    //       data. You can either opt to include it with every single beacon sighting
                    //       for this beacon, or delete it until we get a new / "fresh" TLM frame.
                    //       We'll treat it as "report it only when you see it", so we'll delete it
                    //       each time.
                    self.deviceIDCache.removeValue(forKey: peripheral.identifier)
                    
                    if (self.seenEddystoneCache[beaconInfo.beaconID.description] != nil) {
                        // Reset the onLost timer and fire the didUpdate.
                        if let timer =
                            self.seenEddystoneCache[beaconInfo.beaconID.description]?["onLostTimer"]
                                as? DispatchTimer {
                            timer.reschedule()
                        }
                        
                        self.delegate?.didUpdateBeacon(self, beaconInfo: beaconInfo)
                    } else {
                        // We've never seen this beacon before
                        self.delegate?.didFindBeacon(self, beaconInfo: beaconInfo)
                        
                        let onLostTimer = DispatchTimer.scheduledDispatchTimer(
                            self.onLostTimeout,
                            queue: DispatchQueue.main) {
                                (timer: DispatchTimer) -> () in
                                let cacheKey = beaconInfo.beaconID.description
                                if let
                                    beaconCache = self.seenEddystoneCache[cacheKey],
                                    let lostBeaconInfo = beaconCache["beaconInfo"] as? BeaconInfo {
                                    self.delegate?.didLoseBeacon(self, beaconInfo: lostBeaconInfo)
                                    self.seenEddystoneCache.removeValue(
                                        forKey: beaconInfo.beaconID.description)
                                }
                        }
                        
                        self.seenEddystoneCache[beaconInfo.beaconID.description] = [
                            "beaconInfo" : beaconInfo,
                            "onLostTimer" : onLostTimer
                        ]
                    }
                }
            } else if eft == BeaconInfo.EddystoneFrameType.urlFrameType {
                let serviceUUID = CBUUID(string: "FEAA")
                let _RSSI: Int = RSSI.intValue
                
                if let
                    beaconServiceData = serviceData[serviceUUID] as? Data,
                    let URL = BeaconInfo.parseURLFromFrame(beaconServiceData) {
                    self.delegate?.didObserveURLBeacon(self, URL: URL, RSSI: _RSSI)
                }
            }
        } else {
            NSLog("Unable to find service data; can't process Eddystone")
        }
    }
    
    fileprivate func startScanningSynchronized() {
        if self.centralManager.state != .poweredOn {
            NSLog("CentralManager state is %d, cannot start scan", self.centralManager.state.rawValue)
            self.shouldBeScanning = true
        } else {
            NSLog("Starting to scan for Eddystones")
            let services = [CBUUID(string: "FEAA")]
            let options = [CBCentralManagerScanOptionAllowDuplicatesKey : true]
            self.centralManager.scanForPeripherals(withServices: services, options: options)
        }
    }
}

class iBeaconInfo : NSObject {
    
    var ib: CLBeacon
    
    init(_ ibeacon: CLBeacon){
        ib = ibeacon
    }
    
    var proximityUUID: String {
        return ib.proximityUUID.uuidString
    }
    var major: NSNumber {
        return ib.major
    }
    var minor: NSNumber {
        return ib.minor
    }
    var proximity: Int {
        return ib.proximity.rawValue
    }
    var rssi: Int {
        return ib.rssi
    }
    var accuracy: Double {
        return ib.accuracy
    }
    override var description: String {
        return ib.description
    }


    
}
