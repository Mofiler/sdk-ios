//
//  Mofiler.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/7/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import CoreTelephony
import Darwin

public protocol MofilerDelegate {
    func responseValue(valueData: [String:AnyObject])
}

public class Mofiler: MOGenericManager, NSCoding {
    
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
    
    
    //# MARK: - Prorpeties
    public static let sharedInstance = Mofiler()
    static var initialized = false
    
    public var delegate:MofilerDelegate! = nil
    public var appKey: String = ""                          //Campo obligarotio
    public var appName: String = ""                         //Campo obligarotio
    public var url: String = "mofiler.com:8081"
    public var identities: Array<[String:String]> = []
    public var useLocation: Bool = true                     //defaults to true
    public var useVerboseContext: Bool = false              //defaults to false, but helps Mofiler get a lot of information about the device context
    public var values: Array<[String:String]> = []

    
    //# MARK: - Methods init singleton
    override init() {
        super.init()
        
        if (!Mofiler.initialized) {
            Mofiler.initialized = true;
            generateInstallID()
        }
        sessionControl()
    }
    
    //# MARK: - Methods generate intallID
    func generateInstallID() {
        //Verifica si hay un InstallID, si no hay genera uno que es unico durante la vida de la aplicación
        if UserDefaults.standard.object(forKey: MOMOFILER_APPLICATION_INSTALLID) == nil {
            UserDefaults.standard.set(UUID().uuidString, forKey: MOMOFILER_APPLICATION_INSTALLID)
            UserDefaults.standard.synchronize()
        }
    }
    
    
    //# MARK: - Methods session controll
    func sessionControl() {
        if let startDateSession = UserDefaults.standard.object(forKey: MOMOFILER_SESSION_START_DATE) as? Date, let endDateSession = UserDefaults.standard.object(forKey: MOMOFILER_SESSION_END_DATE) as? Date {
            if 30000 < differenceDatesMilliSeconds(startDate: endDateSession, endDate: Date()) {
                saveSession(startDateSession: startDateSession, endDateSession: endDateSession)
                generateNewSession()
            }
        } else {
            generateNewSession()
        }
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
        
        injectValue(newValue: ["sessionLength":duration], dateOfExpiry: sessionEndTime)
        injectValue(newValue: ["sessionStart":start], dateOfExpiry: sessionEndTime)
        injectValue(newValue: ["sessionEnd":end], dateOfExpiry: sessionEndTime)
    }
    
    func generateNewSession() {
        UserDefaults.standard.set(UUID().uuidString, forKey: MOMOFILER_SESSION_ID)
        UserDefaults.standard.set(Date(), forKey: MOMOFILER_SESSION_START_DATE)
        UserDefaults.standard.synchronize()
    }
    
    func saveSasesionDateEnd() {
        UserDefaults.standard.set(Date(), forKey: MOMOFILER_SESSION_END_DATE)
        UserDefaults.standard.synchronize()
    }
    
    func currentMillis(date: Date) -> Int {
        return Int(date.timeIntervalSince1970) * 1000
    }
    
    func differenceDatesMilliSeconds(startDate: Date, endDate: Date) -> Int {
        let difference = NSCalendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: startDate,  to: endDate)
        if let seconds = difference.second {
            return seconds * 1000
        }
        return 0
    }

    //# MARK: - Methods app enter background, foreground
    override func applicationWillEnterForeground(_ notification: Notification) {
        sessionControl()
    }
    
    override func applicationWillHibernateToBackground(_ notification: Notification) {
        saveSasesionDateEnd()
    }
    
    override func applicationWillTerminate(_ notification: Notification) {
        saveSasesionDateEnd()
    }


    //# MARK: - Methods saving and loading disk.
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        
        if let key = validateStringField(field: aDecoder.decodeObject(forKey: MOMOFILER_APP_KEY)) {
            appKey = key
        }
        if let name = validateStringField(field: aDecoder.decodeObject(forKey: MOMOFILER_APP_NAME)) {
            appName = name
        }
        if let URL = validateStringField(field: aDecoder.decodeObject(forKey: MOMOFILER_URL)) {
            url = URL
        }
        if let ide = validateArrayField(field: aDecoder.decodeObject(forKey: MOMOFILER_IDENTITIES)) {
            identities = ide
        }
        if let location = validateBoolField(field: aDecoder.decodeBool(forKey: MOMOFILER_USE_LOCATION)) {
            useLocation = location
        }
        if let verboseContext = validateBoolField(field: aDecoder.decodeBool(forKey: MOMOFILER_USE_VERBOSE_CONTEXT)) {
            useVerboseContext = verboseContext
        }
        if let val = validateArrayField(field: aDecoder.decodeObject(forKey: MOMOFILER_VALUES)) {
            values = val
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(appKey, forKey: MOMOFILER_APP_KEY)
        aCoder.encode(appName, forKey: MOMOFILER_APP_NAME)
        aCoder.encode(url, forKey: MOMOFILER_URL)
        aCoder.encode(identities, forKey: MOMOFILER_IDENTITIES)
        aCoder.encode(useLocation, forKey: MOMOFILER_USE_LOCATION)
        aCoder.encode(useVerboseContext, forKey: MOMOFILER_USE_VERBOSE_CONTEXT)
        aCoder.encode(values, forKey: MOMOFILER_VALUES)
    }
    
    //# MARK: - Methods initialize keys and injects
    public func initializeWith(appKey: String, appName: String, identity: [String:String]) {
        self.appKey = appKey
        self.appName = appName
        identities.append(identity)
    }
    
    public func addIdentity(newValue: [String:String]) {
        values.append(newValue)
    }
    
    public func injectValue(newValue: [String:String]) {
        if validateFieldsMandatory() {
            values.append(newValue)
            
            if values.count >= 10 {
                flushDataToMofiler()
            }
        } else {
            print("Error: ")
        }
    }
    
    public func injectValue(newValue: [String:String], dateOfExpiry: Float) {
        
        if validateFieldsMandatory() {
            //TODO que hacer con el expiry
            values.append(newValue)
            if values.count >= 10 {
                flushDataToMofiler()
            }
        } else {
            print("Error: ")
        }
    }
    
    
    
    
    //# MARK: - Methods Post and get API
    public func flushDataToMofiler() {
        //TODO POST API
        if validateFieldsMandatory() {
            if values.count > 0 {
//        let valuesAux: Array<[String:String]> = values
//        values = []
                
                //Success
                    //NO HACE NADA
                
                //Fail
                    //Hacer backup
                    //let newValues = valuesAux + values
                    //values = []
                    //values = newValues
            }
        } else {
            print("Error: ")
        }
    }
    
    public func getValue(key: String, identityKey: String, identityValue: String) {
        //TODO GET API
        if validateFieldsMandatory() {
            //        if let delegate = delegate {
            //            //delegate.responseValue(valueData: ["":""])
            //        } else {
            //            //ERROR response no tiene delegate
            //        }
        } else {
            print("Error: ")
        }
    }
    
    //# MARK: - Methods Device info
    public func testDevice() {
        reportCarrier()
        reportMemory()
        reportDisk()
    }
    
    //# MARK: - Methods Carrier info
    func reportCarrier() {
        print("\nCARRIER")
        
        let netinfo = CTTelephonyNetworkInfo()
        print("\ncurrentRadioAccessTechnology: ", netinfo.currentRadioAccessTechnology)
        
        let carrier = netinfo.subscriberCellularProvider
        print("\n carrierName: ", carrier?.carrierName)
        print("\n mobileCountryCode: ", carrier?.mobileCountryCode)
        print("\n mobileNetworkCode: ", carrier?.mobileNetworkCode)
        print("\n isoCountryCode: ", carrier?.isoCountryCode)
        print("\n allowsVOIP: ", carrier?.allowsVOIP)
    }
    
    //# MARK: - Methods Memory info
    func reportMemory() {
        let HOST_BASIC_INFO_COUNT = MemoryLayout<host_basic_info>.stride/MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(HOST_BASIC_INFO_COUNT)
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: HOST_BASIC_INFO_COUNT) {
            host_info(mach_host_self(), HOST_BASIC_INFO, $0, &size)
        }
        
        print("\nMEMORY")
        print("\n max_cpus: ", hostInfo.pointee.max_cpus)
        print("\n avail_cpus: ", hostInfo.pointee.avail_cpus)
        print("\n memory_size: ", hostInfo.pointee.memory_size)
        print("\n max_mem: ", hostInfo.pointee.max_mem)
        
        hostInfo.deallocate(capacity: 1)
    }
    
    //# MARK: - Methods disk info
    func reportDisk() {
        print("\nDISK")
        print(" totalDiskSpace: ",totalDiskSpace(),
              "\n freeDiskSpace: ", freeDiskSpace(),
              "\n usedDiskSpace: ", usedDiskSpace(),
              "\n totalDiskSpaceInBytes: ", totalDiskSpaceInBytes(),
              "\n freeDiskSpaceInBytes: ", freeDiskSpaceInBytes(),
              "\n usedDiskSpaceInBytes: ", usedDiskSpaceInBytes(),
              "\n numberOfNodes: ", numberOfNodes(),"\n")
    }
    
    func memoryFormatter(diskSpace: Double) -> String {
        let bytes:Double = 1.0 * diskSpace
        let megabytes:Double = bytes / 1048576.0
        let gigabytes:Double = bytes / 1073741824.0
        
        if gigabytes >= 1.0 {
            return String(format: "%.2f GB", gigabytes)
        } else if megabytes >= 1.0 {
            return String(format: "%.2f MB", megabytes)
        } else {
            return String(format: "%.2f bytes", bytes)
        }
    }
    
    func diskSpaceInBytes(type: FileAttributeKey) -> Double {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
            if let fileSize = (systemAttributes[type] as? Double) {
                return fileSize
            }
        } catch { }
        return 0.0
    }
    
    func totalDiskSpaceInBytes() -> Double {
        return diskSpaceInBytes(type: FileAttributeKey.systemSize)
    }
    
    func freeDiskSpaceInBytes() -> Double {
        return diskSpaceInBytes(type: FileAttributeKey.systemFreeSize)
    }
    
    func usedDiskSpaceInBytes() -> Double {
        return totalDiskSpaceInBytes() - freeDiskSpaceInBytes()
    }
    
    func totalDiskSpace() -> String {
        return memoryFormatter(diskSpace: totalDiskSpaceInBytes())
    }
    
    func freeDiskSpace() -> String {
        return memoryFormatter(diskSpace: freeDiskSpaceInBytes())
    }
    
    func usedDiskSpace() -> String {
        return memoryFormatter(diskSpace: usedDiskSpaceInBytes())
    }
    
    /*! WORK IN PROGRESS */
    func numberOfNodes() -> Double {
        return diskSpaceInBytes(type: FileAttributeKey.systemNodes)
    }

    
    
    //# MARK: - Methods validate fields
    func validateStringField(field: Any?) -> String? {
        if let field = field , field is String {
            return field as? String
        }
        return nil
    }
    
    func validateArrayField(field: Any?) -> Array<[String:String]>? {
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
    
    func validateFieldsMandatory() -> Bool {
        return appKey.characters.count > 0 && appName.characters.count > 0 && identities.count > 0
    }

}
