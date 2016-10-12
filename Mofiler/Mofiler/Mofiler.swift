//
//  Mofiler.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/7/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import UIKit
import CoreTelephony

import Darwin

public protocol MofilerDelegate {
    func responseValue(valueData: [String:AnyObject])
}

public class Mofiler: NSObject {
    
    public static let sharedInstance = Mofiler()
    static var initialized = false
    public var delegate:MofilerDelegate! = nil
    
    public var appKey: String?                             //Campo obligarotio
    public var appName: String?                            //Campo obligarotio
    public var url: String? = "mofiler.com:8081"
    public var identities: Array<[String:String]> = []
    public var useLocation = true                          //defaults to true
    public var UseVerboseContext = false                   //defaults to false, but helps Mofiler get a lot of information about the device context
    
    public var values: Array<[String:String]> = []
    
    override init() {
        super.init()
        if (!Mofiler.initialized) {
            Mofiler.initialized = true;
        }
    }
    
    public func initializeWith(appKey: String, appName: String, identity: [String:String]) {
        self.appKey = appKey
        self.appName = appName
        self.identities.append(identity)
    }
    
    public func addIdentity(newValue: [String:String]) {
        values.append(newValue)
    }
    
    public func injectValue(newValue: [String:String]) {
        values.append(newValue)
    }
    
    public func injectValue(newValue: [String:String], dateOfExpiry: Float) {
        //TODO expiry
        values.append(newValue)
    }
    
    public func flushDataToMofiler() {
        //TODO POST API
    }
    
    public func getValue(key: String, identityKey: String, identityValue: String) {
        //TODO GET API
        //delegate.responseValue(valueData: ["":""])
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
    
}
