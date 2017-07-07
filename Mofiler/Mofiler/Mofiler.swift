//
//  Mofiler.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/7/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import CoreTelephony
import Darwin
import CoreLocation
import AdSupport
import CoreBluetooth

@objc public protocol MofilerDelegate {
    @objc optional func responseValue(key: String, identityKey: String, identityValue: String, value: [String:Any])
    @objc optional func errorOcurred(error: String, userInfo: [String: String])
}

public class Mofiler: MOGenericManager, CLLocationManagerDelegate, MODiskCacheProtocol, CBCentralManagerDelegate {
    
    //# MARK: - Keys to save to disk
    let MOMOFILER_APP_KEY               = "MOMOFILER_APP_KEY"
    let MOMOFILER_APP_NAME              = "MOMOFILER_APP_NAME"
    let MOMOFILER_URL                   = "MOMOFILER_URL"
    let MOMOFILER_IDENTITIES            = "MOMOFILER_IDENTITIES"
    let MOMOFILER_USE_LOCATION          = "MOMOFILER_USE_LOCATION"
    let MOMOFILER_USE_VERBOSE_CONTEXT   = "MOMOFILER_USE_VERBOSE_CONTEXT"
    let MOMOFILER_VALUES                = "MOMOFILER_VALUES"
    
    //# MARK: - Keys session and installid
    let MOMOFILER_APPLICATION_INSTALLID = "MOMOFILER_APPLICATION_INSTALLID"
    let MOMOFILER_SESSION_ID            = "MOMOFILER_SESSION_ID"
    let MOMOFILER_SESSION_START_DATE    = "MOMOFILER_SESSION_START_DATE"
    let MOMOFILER_SESSION_END_DATE      = "MOMOFILER_SESSION_END_DATE"
    
    //# MARK: - Errors
    let MOMOFILER_ERROR_CODE_KEY        = "MOMOFILER_ERROR_CODE_KEY"
    let MOMOFILER_ERROR_NOT_INITIALIZED = "MOMOFILER_ERROR_NOT_INITIALIZED"
    let MOMOFILER_ERROR_NOT_DELEGATE    = "MOMOFILER_ERROR_NOT_DELEGATE"
    let MOMOFILER_ERROR_API             = "MOMOFILER_ERROR_API"
    let MOMOFILER_ERROR_CONVERT_JSON    = "MOMOFILER_ERROR_CONVERT_JSON"
    let MOMOFILER_ERROR_LOCATION        = "MOMOFILER_ERROR_LOCATION"
    
    let MO_STORE_CACHEDOBJECTS          = "MO_STORE_CACHEDOBJECTS"
    
    let MOFILER_ADVERTISING_ID          = "advertisingIdentifier"
    
    let MOFILER_INSTALL_ID              = "mofilerInstallId"
    
    let VALUES_COUNT:Int = 10;

    //# MARK: - Properties
    public static let sharedInstance = Mofiler()
    static var initialized = false
    public var isInitialized = false
    
    public var delegate: MofilerDelegate? = nil
    public var appKey: String = ""                          //Required field
    public var appName: String = ""                         //Required field
    public var url: String = "mofiler.com"
    public var identities: Array<[String:String]> = []
    public var useVerboseContext: Bool = false              //defaults to false, but helps Mofiler get a lot of information about the device context
    public var values: Array<[String : Any]> = []
    public var sessionTimeoutAfterEnd = 30000
    public var debugLogging = true
    public var isLoadingPost = false
    
    var useLocation: Bool = true                     //defaults to true
    var latitude: Float?
    var longitude: Float?
    
    var mofilerProbeTimer: Timer?
    var mofilerProbeInterval:Double = 1800 //30 minutes
    
    //# MARK: - Methods init singleton
    override init() {
        super.init()
        
        if (!Mofiler.initialized) {
            Mofiler.initialized = true;
            generateInstallID()
        }
        
        MODiskCache.sharedInstance.registerForDiskCaching("Mofiler", object: self)
        
        mofilerProbeTimer = Timer.scheduledTimer(timeInterval: mofilerProbeInterval, target: self, selector: #selector(injectMofilerProbe), userInfo: nil, repeats: true)
    }
    
    //# MARK: - Methods generate intallID
    func generateInstallID() {
        if UserDefaults.standard.object(forKey: MOMOFILER_APPLICATION_INSTALLID) == nil {
            UserDefaults.standard.set(UUID().uuidString, forKey: MOMOFILER_APPLICATION_INSTALLID)
            UserDefaults.standard.synchronize()
        }
    }
    
    
    //# MARK: - Methods session controll
    func sessionControl() {
        if let startDateSession = UserDefaults.standard.object(forKey: MOMOFILER_SESSION_START_DATE) as? Date, let endDateSession = UserDefaults.standard.object(forKey: MOMOFILER_SESSION_END_DATE) as? Date {
            if sessionTimeoutAfterEnd < differenceDatesMilliSeconds(startDate: endDateSession, endDate: Date()) {
                saveSession(startDateSession: startDateSession, endDateSession: endDateSession)
                generateNewSession()
            }
        } else {
            generateNewSession()
        }
    }
    
    func debugLog(log: String) {
        if debugLogging {
            print(log)
        }
    }
    
    func errorOcurred(error: String, userInfo: [String: String]) {
        debugLog(log: error)
        if let delegate = delegate, let errorOcurred = delegate.errorOcurred {
            errorOcurred(error, userInfo)
        }
    }
    
    func errorNotInitialized() {
        errorOcurred(error: "The SDK was not initialized properly. Please set appName, appKey and at least one identity before using it.", userInfo: [MOMOFILER_ERROR_CODE_KEY : MOMOFILER_ERROR_NOT_INITIALIZED])
    }
    
    func errorDelegate() {
        errorOcurred(error: "The SDK was not initialized properly. Please set delegate.", userInfo: [MOMOFILER_ERROR_CODE_KEY : MOMOFILER_ERROR_NOT_DELEGATE])
    }
    
    
    
    func saveSession(startDateSession: Date, endDateSession: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let start = formatter.string(from: startDateSession)
        let end = formatter.string(from: endDateSession)
        
        let sessionEndTime = Float(currentMillis(date: endDateSession))
        let duration = String(differenceDatesMilliSeconds(startDate: startDateSession, endDate: endDateSession))
        
        injectValue(newValue: ["sessionLength":duration], expirationDateInMilliseconds: sessionEndTime as NSNumber)
        injectValue(newValue: ["sessionStart":start], expirationDateInMilliseconds: sessionEndTime as NSNumber)
        injectValue(newValue: ["sessionEnd":end], expirationDateInMilliseconds: sessionEndTime as NSNumber)
        //flushDataToMofiler()
        
        let when = DispatchTime.now() + 2 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.flushDataToMofiler();
        }

    }
    
    func generateNewSession() {
        UserDefaults.standard.set(UUID().uuidString, forKey: MOMOFILER_SESSION_ID)
        UserDefaults.standard.set(Date(), forKey: MOMOFILER_SESSION_START_DATE)
        UserDefaults.standard.set(nil, forKey: MOMOFILER_SESSION_END_DATE)
        UserDefaults.standard.synchronize()
    }
    
    func saveSasesionDateEnd() {
        UserDefaults.standard.set(Date(), forKey: MOMOFILER_SESSION_END_DATE)
        UserDefaults.standard.synchronize()
    }
    
    func currentMillis(date: Date) -> Int64 {
        return Int64(date.timeIntervalSince1970) * 1000
    }
    
    func differenceDatesMilliSeconds(startDate: Date, endDate: Date) -> Int {
//        let difference = NSCalendar.current.dateComponents([.second], from: startDate,  to: endDate)
//        if let seconds = difference.second {
//            return seconds * 1000
//            NSLog("----seconds", seconds)
//        }
        let elapsed = endDate.timeIntervalSince(startDate);
        NSLog("----elapsed", elapsed)

        return Int(elapsed*1000)
    }

    //# MARK: - Methods app enter background, foreground
    override func applicationWillEnterForeground(_ notification: Notification) {
        mofilerProbeTimer = Timer.scheduledTimer(timeInterval: mofilerProbeInterval, target: self, selector: #selector(injectMofilerProbe), userInfo: nil, repeats: true)
        sessionControl()
    }
    
    override func applicationWillHibernateToBackground(_ notification: Notification) {
        if let mofilerProbeTimer = mofilerProbeTimer {
            mofilerProbeTimer.invalidate()
        }
        saveSasesionDateEnd()
    }
    
    override func applicationWillTerminate(_ notification: Notification) {
        if let mofilerProbeTimer = mofilerProbeTimer {
            mofilerProbeTimer.invalidate()
        }
        saveSasesionDateEnd()
    }

    //# MARK: - Methods initialize keys and injects
    public func initializeWith(appKey: String, appName: String, useLoc: Bool = true, useAdvertisingId: Bool = true) {
        self.appKey = appKey
        self.appName = appName
        
        // clear identities
        //identities = []
        
        useLocation = useLoc
        if (useLoc) {
            determineMyCurrentLocation()
        }

        // add installID as identity too
        if let installID = UserDefaults.standard.object(forKey: Mofiler.sharedInstance.MOMOFILER_APPLICATION_INSTALLID) as? String {
//            identities.append(["name":MOFILER_INSTALL_ID,"value":installID])
            addIdentity(identity: [MOFILER_INSTALL_ID: installID])
        }
        
        if getIdentity(_key: MOFILER_ADVERTISING_ID) == nil {
            if (useAdvertisingId) {
                if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                    identities.append(["name":MOFILER_ADVERTISING_ID,"value":ASIdentifierManager.shared().advertisingIdentifier.uuidString])
                }
                injectValue(newValue: ["_initialized" : String(NSDate().timeIntervalSince1970*1000)])
                
                let when = DispatchTime.now() + 2 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    self.flushDataToMofiler();
                }
            }
        }
        
        self.isInitialized = true;
        sessionControl();
        
        MODiskCache.sharedInstance.saveCacheToDisk()
    }
    
    public func addIdentity(identity: [String:String]) {
        validateIdentity(identity: identity)
        if let key = identity.first?.key, let value = identity.first?.value {
            identities.append(["name":key,"value":value])
        }
        MODiskCache.sharedInstance.saveCacheToDisk()
    }
    
    public func getIdentity(_key: String) -> [String:String]?{
//        return identities.first(where: { $0.name == _name})
//        if let i = identities.index(where: { $0.key == _name }) {
//            return identities[i]
//        }
//        return nil
        let identitiesAux = identities
        for (idx, identi) in identitiesAux.enumerated() {
            if let key = identi.first?.value, key == _key {
                return identities[idx]
            }
        }
         return nil

    
    }
    
    func validateIdentity(identity: [String:String]) {
        let identitiesAux = identities
        for (idx, identi) in identitiesAux.enumerated() {
            if let key = identi.first?.value, let newKey = identity.first?.key, key == newKey {
                identities.remove(at: idx)
            }
        }
    }

    public func setSdkTypeAndVersion(sdk_type: String, sdk_version: String) {
        MODeviceManager.sharedInstance.setSdkTypeAndVersion(sdk_type: sdk_type, sdk_version: sdk_version)
    }
    
    
    public func injectValue(newValue: [String:Any], expirationDateInMilliseconds: NSNumber? = nil) {
        if validateMandatoryFields() {
            
            if let keyValue = newValue.first?.key, let value = newValue.first?.value {
                var dataValue:[String:Any] = [:]
                let milis = NSNumber(value: currentMillis(date: Date()))
                if let expirationDateInMilliseconds = expirationDateInMilliseconds {
                    if let latitude = latitude, let longitude = longitude {
                        dataValue = [keyValue: value, "tstamp":milis, "expireAfter":expirationDateInMilliseconds as NSNumber, "location":["latitude":String(format: "%f", latitude),"longitude":String(format: "%f", longitude)]]
                    } else {
                        dataValue = [keyValue: value, "tstamp":milis, "expireAfter":expirationDateInMilliseconds as NSNumber]
                    }
                } else {
                    if let latitude = latitude, let longitude = longitude {
                        dataValue = [keyValue: value, "tstamp":milis, "location":["latitude":String(format: "%f", latitude),"longitude":String(format: "%f", longitude)]]
                    } else {
                        dataValue = [keyValue: value, "tstamp":milis]
                    }
                }
                
                values.append(dataValue)
                MODiskCache.sharedInstance.saveCacheToDisk()
            }
            
            if values.count >= VALUES_COUNT {
                flushDataToMofiler()
            }
            
        } else {
            errorNotInitialized()
        }
    }
    
    func injectMofilerProbe() {

        if (useVerboseContext) {
            if validateMandatoryFields() {
                values.append(["mofiler_probe":MODeviceManager.sharedInstance.loadExtras()])
                MODiskCache.sharedInstance.saveCacheToDisk()
                if values.count >= VALUES_COUNT {
                    flushDataToMofiler()
                }
            } else {
                errorNotInitialized()
            }
        }
    }
    
    //# MARK: - Methods Post and get API
    public func flushDataToMofiler() {
        if !isLoadingPost {
            if validateMandatoryFields() {
                if values.count > 0 {
                    self.isLoadingPost = true
                    let data = MODeviceManager.sharedInstance.loadData(userValues: values, identities: identities)
                    //let countDeleteItems = values.count - 1
                    let countDeleteItems = values.count
                    MOAPIManager.sharedInstance.uploadValues(urlBase: url, appKey: appKey, appName: appName, data: data, callback: { (result, error) in
                        
                        performBlockOnMainQueue {
                            self.isLoadingPost = false
                            if let error = error {
                                self.errorOcurred(error: error, userInfo: [self.MOMOFILER_ERROR_API : self.MOMOFILER_ERROR_API])
                            } else if let result = result as? [String : Any] {
                                
                                if let _ = result["error"] {
                                    self.errorOcurred(error: "Error", userInfo: [self.MOMOFILER_ERROR_API : self.MOMOFILER_ERROR_API])
                                } else {
                                    let valuesAux = self.values
                                    for (idx, _) in valuesAux.enumerated() {
                                        if idx < countDeleteItems {
                                            self.values.removeFirst()
                                        }
                                    }
                                    
                                    MODiskCache.sharedInstance.saveCacheToDisk()
                                }
                            } else {
                                self.errorOcurred(error: "Error", userInfo: [self.MOMOFILER_ERROR_API : self.MOMOFILER_ERROR_API])
                            }    
                        }
                        
                    })
                }
            } else {
                errorNotInitialized()
            }
        }
    }
    
    public func getValue(key: String, identityKey: String, identityValue: String) {
        
        if validateMandatoryFields() {
            if let delegate = delegate, let responseValue = delegate.responseValue {
                
                MOAPIManager.sharedInstance.getValue(identityKey: identityKey, identityValue: identityValue, keyToRetrieve: key, urlBase: url, appKey: appKey, appName: appName, device: "apple", callback: { (result, error) in
                    
                    performBlockOnMainQueue {
                        if let error = error {
                            self.errorOcurred(error: error, userInfo: [self.MOMOFILER_ERROR_API : self.MOMOFILER_ERROR_API])
                        } else if let result = result as? [String : Any]{
                            responseValue(key, identityKey, identityValue, result)
                        } else {
                            self.errorOcurred(error: "Error", userInfo: [self.MOMOFILER_ERROR_API : self.MOMOFILER_ERROR_API])
                        }
                    }
                    
                })
            } else {
                errorDelegate()
            }
        } else {
            errorNotInitialized()
        }
    }
    
    public func getValue(key: String, identityKey: String, identityValue: String, callback: @escaping (Any?, Any?) -> Void) {
     
        if validateMandatoryFields() {
            MOAPIManager.sharedInstance.getValue(identityKey: identityKey, identityValue: identityValue, keyToRetrieve: key, urlBase: url, appKey: appKey, appName: appName, device: "apple", callback: { (result, error) in
                if error != nil {
                    callback(nil, ["error":error, self.MOMOFILER_ERROR_API:self.MOMOFILER_ERROR_API])
                } else if let result = result as? [String : Any]{
                    callback(["key":key, "identityKey":identityKey, "identityValue":identityValue, "value":result] , nil)
                } else {
                    callback(nil, ["error":"Error", self.MOMOFILER_ERROR_API:self.MOMOFILER_ERROR_API])
                }
            })
            
        } else {
            errorNotInitialized()
        }
    }
    
    var beaconList = [(CLBeaconRegion, CLBeacon)]()
    var blueToothReady = false
    var centralManager:CBCentralManager!
    var scannedBeacons: [ScannedBeacon] = []
    var updateTimer: Timer?
    
    //# MARK: - Location
    func determineMyCurrentLocation() {

        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            
            //beacons by region
            //TODO bring list from server
            let beaconRegions = [
                CLBeaconRegion(proximityUUID: NSUUID(uuidString: "F7826DA6-4FA2-4E98-8024-BC5B71E0893E")! as UUID, identifier: "Kontakt"),
                CLBeaconRegion(proximityUUID: NSUUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")! as UUID, identifier: "Estimote")
            ]
            
            beaconRegions.forEach{region in
                locationManager.startRangingBeacons(in: region)
            }
        }
        
        // bluetooth devices (beacons and others)
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        
    }
    
    // LOCATION
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.latitude = Float(location.coordinate.latitude)
            self.longitude = Float(location.coordinate.longitude)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        self.errorOcurred(error: "Error \(error.localizedDescription)", userInfo: [self.MOMOFILER_ERROR_LOCATION : self.MOMOFILER_ERROR_LOCATION])
    }
    // END LOCATION
    
    // BEACON REGION
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        // 1
        var outputText = "Ranged beacons count: \(beacons.count)\n\n"
        beacons.forEach { beacon in
            outputText += beacon.description
            outputText += "\n\n"
        }
        NSLog("%@", outputText)
        
        // 2
        beacons.forEach { beacon in
            if let index = beaconList.index(where: { $0.1.proximityUUID.uuidString == beacon.proximityUUID.uuidString && $0.1.major == beacon.major && $0.1.minor == beacon.minor }) {
                beaconList[index] = (region, beacon)
            } else {
                beaconList.append((region, beacon))
            }
        }
        
    }
    // END BEACON REGION
    
    // BLUETOOH
    //Callback where we receive the Central Manager state. When state is "Powered ON" start the scan.
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            print("CoreBluetooth BLE hardware is powered off")
        case .poweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready")
            blueToothReady = true;
            
        default: break
        }
        
        if blueToothReady {
            //Start scanning for devices
            discoverDevices()
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
        if(scannedBeacons.count>0){
            for i in 0...(scannedBeacons.count-1){
                if(i<scannedBeacons.count && peripheral.identifier.uuidString == scannedBeacons[i].bUUID){
                    scannedBeacons[i] = ScannedBeacon(peri: peripheral, name: namee, uuid: peripheral.identifier.uuidString, rssi: RSSI.intValue)
                    contains = true
                    break
                }
            }
        }
        if(!contains){
            NSLog("new device found \(namee) - \(RSSI)")
            scannedBeacons.append(ScannedBeacon(peri:peripheral, name: namee, uuid: peripheral.identifier.uuidString, rssi: RSSI.intValue))
            //"peripheral":peripheral,
            let bt_device: [String:Any] = [
                                           "name": namee,
                                           "uuid": peripheral.identifier.uuidString,
                                           "rssi": RSSI.intValue]
            
            injectValue(newValue: ["_btdevice" : bt_device])
            if (RSSI.intValue > -15 || RSSI.intValue < -35) {
                // With those RSSI values, probably not an iBeacon.
            } else {
                // Try to obtain beacon information
                centralManager.connect(peripheral, options: nil);
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        discoveredPeripheral = nil
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard error == nil else {
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard error == nil else {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid.uuidString == "2B24" { // UUID
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            return;
        }
        
        if value = characteristic.value {
            // value will be a Data object with bits that represent the UUID you're looking for.
            print("Found beacon UUID: \(value.hexString)")
            // This is where you can start the CLBeaconRegion and start monitoring it, or just get the value you need.
        }
    }
    // END BLUETOOH
    
    //# MARK: - Methods validate fields
    func validateStringField(field: Any?) -> String? {
        if let field = field , field is String {
            return field as? String
        }
        return nil
    }
    
    func validateArrayField(field: Any?) -> Array<[String:Any]>? {
        if let field = field , field is Array<[String:Any]> {
            return field as? Array<[String:Any]>
        }
        return nil
    }
    
    func validateArrayFieldString(field: Any?) -> Array<[String:String]>? {
        if let field = field , field is Array<[String:String]> {
            return field as? Array<[String:String]>
        }
        return nil
    }
    
    func validateBoolField(field: Any?) -> Bool? {
        if let field = field , field is Bool {
            return field as? Bool
        }
        return nil
    }
    
    func validateMandatoryFields() -> Bool {
        return appKey.characters.count > 0 && appName.characters.count > 0 && identities.count > 0
    }
    
    //# MARK: - MODiskCacheProtocol
    func dataToCacheForDiskCache(_ diskCache: MODiskCache) -> [String : Any]? {
        return [MOMOFILER_APP_KEY               : appKey,
                MOMOFILER_APP_NAME              : appName,
                MOMOFILER_URL                   : url,
                MOMOFILER_IDENTITIES            : identities,
                MOMOFILER_USE_LOCATION          : useLocation,
                MOMOFILER_USE_VERBOSE_CONTEXT   : useVerboseContext,
                MOMOFILER_VALUES                : values]
    }
    
    func loadDataFromCache(_ data: [String : Any], diskCache: MODiskCache) {
        if let obj = data[MOMOFILER_APP_KEY] as? String {
            appKey = obj
        }
        if let obj = data[MOMOFILER_APP_NAME] as? String {
            appName = obj
        }
        if let obj = data[MOMOFILER_URL] as? String {
            url = obj
        }
        if let obj = data[MOMOFILER_IDENTITIES] as? Array<[String:String]> {
            identities = obj
        }
        if let obj = data[MOMOFILER_USE_LOCATION] as? Bool {
            useLocation = obj
        }
        if let obj = data[MOMOFILER_USE_VERBOSE_CONTEXT] as? Bool {
            useVerboseContext = obj
        }
        if let obj = data[MOMOFILER_VALUES] as? Array<[String:Any]> {
            values = obj
        }
    }

}

//Beacon class which defines the structure of the data we need.
class ScannedBeacon {
    
    var mPeri: CBPeripheral
    var bName: String
    var bUUID: String
    var bRssi: Int
    
    
    init(peri: CBPeripheral, name: String, uuid: String, rssi: Int) {
        self.mPeri = peri
        self.bName = name
        self.bUUID = uuid
        self.bRssi = rssi
    }
}
