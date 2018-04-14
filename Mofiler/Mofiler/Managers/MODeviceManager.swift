//
//  MODeviceManager.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/18/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import Foundation
import CoreTelephony
import Darwin
import UIKit
import SystemConfiguration.CaptiveNetwork

class MODeviceManager: MOGenericManager {
    
    //# MARK: - Keys
    let MOMOFILER_DEVICE_ID                         = "MOMOFILER_DEVICE_ID"
    let MOMOFILER_DEVICE_USER_VALUES                = "user_values"
    let MOMOFILER_DEVICE_IDENTITY                   = "identity"
    let MOMOFILER_DEVICE_CONTEXT                    = "mofiler_device_context"
    let MOMOFILER_DEVICE_MANUFACTURER               = "manufacturer"
    let MOMOFILER_DEVICE_MODEL                      = "model"
    let MOMOFILER_DEVICE_DISPLAY                    = "display"
    let MOMOFILER_DEVICE_LOCALE                     = "locale"
    let MOMOFILER_DEVICE_XMOFILER_SESSIONID         = "X­Mofiler­SessionID"
    let MOMOFILER_DEVICE_XMOFILER_INSTALLID         = "X-Mofiler-InstallID"
    let MOMOFILER_DEVICE_EXTRAS                     = "extras"
    let MOMOFILER_DEVICE_PHONETYPE                  = "phonetype"
    let MOMOFILER_DEVICE_OPERATOR_MCC               = "operator_mcc"
    let MOMOFILER_DEVICE_OPERATOR_MCCMNC            = "operator_mccmnc"
    let MOMOFILER_DEVICE_OPERATOR_NAME              = "operator_name"
    let MOMOFILER_DEVICE_SIM_OPERATOR_NAME          = "sim_operator_name"
    let MOMOFILER_DEVICE_SIM_OPERATOR_MCCMNC        = "sim_operator_mccmnc"
    let MOMOFILER_DEVICE_DEVICE_ID                  = "device_id"
    let MOMOFILER_DEVICE_MAX_CPUS                   = "max_cpus"
    let MOMOFILER_DEVICE_AVAIL_CPUS                 = "avail_cpus"
    let MOMOFILER_DEVICE_MEMORY_SIZE                = "memory_size"
    let MOMOFILER_DEVICE_MAX_MEN                    = "max_men"
    let MOMOFILER_DEVICE_TOTAL_DISK_SPACE           = "totalDiskSpace"
    let MOMOFILER_DEVICE_FREE_DISK_SPACE            = "freeDiskSpace"
    let MOMOFILER_DEVICE_USED_DISK_SPACE            = "usedDiskSpace"
    let MOMOFILER_DEVICE_TOTAL_DISK_SPACE_IN_BYTES  = "totalDiskSpaceInBytes"
    let MOMOFILER_DEVICE_FREE_DISK_SPACE_IN_BYTES   = "freeDiskSpaceInBytes"
    let MOMOFILER_DEVICE_USED_DISK_SPACE_IN_BYTES   = "usedDiskSpaceInBytes"
    let MOMOFILER_DEVICE_SCREEN_ORIENTATION         = "orientation"
    let MOMOFILER_DEVICE_SCREEN_INFO                = "screenInfo"
    let MOMOFILER_BATTERY_INFO                      = "batteryInfo"

    let MOMOFILER_DEVICE_OS_NAME                    = "os_name"
    let MOMOFILER_DEVICE_OS_NAME_IOS                = "iOS"
    let MOMOFILER_DEVICE_OS_VERSION                 = "os_version"
    let MOMOFILER_DEVICE_SDK_TYPE                   = "sdk_type"
    var MOMOFILER_DEVICE_SDK_TYPE_NAME              = "iPhone SDK"
    let MOMOFILER_DEVICE_SDK_VERSION                = "sdk_version"
    var MOMOFILER_DEVICE_SDK_VERSION_N              = "1.1.6"
    
    let MOMOFILER_DEVICE_MODEL_NAME                 = "model"
    let MOMOFILER_DEVICE_NAME                       = "deviceName"
    let MOMOFILER_DEVICE_IDENTIFIER_FOR_VENDOR      = "identifierForVendor"
    let MOMOFILER_DEVICE_NETWORK_SSID               = "networkSSID"

    
    static let sharedInstance = MODeviceManager()
    static var initialized = false
    
    //# MARK: - Methods init singleton
    override init() {
        super.init()
        
        if (!MODeviceManager.initialized) {
            MODeviceManager.initialized = true;
            
            UserDefaults.standard.set(UUID().uuidString, forKey: MOMOFILER_DEVICE_ID)
            UserDefaults.standard.synchronize()
            
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
    }
    
    //# MARK: - Methods Device info
    func loadData (userValues: Array<[String:Any]>, identities: Array<[String:Any]>) -> [String:Any]{
        let data: [String : Any] = [MOMOFILER_DEVICE_USER_VALUES:   userValues,
                                    MOMOFILER_DEVICE_IDENTITY:      identities,
                                    MOMOFILER_DEVICE_CONTEXT:       loadMofilerDeviceContext()]
        return data
    }
    
    func loadMofilerDeviceContext() -> [String:Any] {
        
        let netinfo = CTTelephonyNetworkInfo()
        let carrier = netinfo.subscriberCellularProvider
        
        var installID = ""
        if let installid = UserDefaults.standard.object(forKey: Mofiler.sharedInstance.MOMOFILER_APPLICATION_INSTALLID) as? String {
            installID = installid
        }
        
        var sessionID = ""
        if let sessionid = UserDefaults.standard.object(forKey: Mofiler.sharedInstance.MOMOFILER_SESSION_ID) as? String {
            sessionID = sessionid
        }
        
        var isoCountryCode = ""
        if let carrier = carrier, let isoCC = carrier.isoCountryCode {
            isoCountryCode = isoCC
        }

        let mofiler_device_context: [String:Any] = [MOMOFILER_DEVICE_MANUFACTURER:"Apple",
                                                    MOMOFILER_DEVICE_MODEL: UIDevice.current.modelName,
                                                    MOMOFILER_DEVICE_DISPLAY: String(format:"%fx%f", UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height),
                                                    MOMOFILER_DEVICE_LOCALE:isoCountryCode,
                                                    MOMOFILER_DEVICE_XMOFILER_SESSIONID:sessionID,
                                                    MOMOFILER_DEVICE_XMOFILER_INSTALLID:installID,
                                                    MOMOFILER_DEVICE_EXTRAS:loadExtras()]
        return mofiler_device_context
    }
    
    func loadExtras() -> [String:Any] {
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        let netinfo = CTTelephonyNetworkInfo()
        let carrier = netinfo.subscriberCellularProvider
        
        var deviceID = ""
        if let deviceid = UserDefaults.standard.object(forKey: MOMOFILER_DEVICE_ID) as? String {
            deviceID = deviceid
        }
        
        //RAM
        let HOST_BASIC_INFO_COUNT = MemoryLayout<host_basic_info>.stride/MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(HOST_BASIC_INFO_COUNT)
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: HOST_BASIC_INFO_COUNT) {
            host_info(mach_host_self(), HOST_BASIC_INFO, $0, &size)
        }
        
        var currentRadioAccessTechnology = ""
        var mobileCountryCode = ""
        var mobileNetworkCode = ""
        var carrierName = ""
        if let currentRAT = netinfo.currentRadioAccessTechnology, let carrier = carrier, let mobileCC = carrier.mobileCountryCode, let mobileNC = carrier.mobileNetworkCode, let carrierN = carrier.carrierName {
            currentRadioAccessTechnology = currentRAT
            mobileCountryCode = mobileCC
            mobileNetworkCode = mobileNC
            carrierName = carrierN
        }

        // now calculate orientation
        var orientationValue = 0
        switch UIDevice.current.orientation {
            case UIDeviceOrientation.portrait:
                orientationValue = 1
            case UIDeviceOrientation.portraitUpsideDown:
                orientationValue = 2
            case UIDeviceOrientation.landscapeLeft:
                orientationValue = 0
            case UIDeviceOrientation.landscapeRight:
                orientationValue = 3
            case UIDeviceOrientation.unknown:
                orientationValue = 4
            case UIDeviceOrientation.faceUp:
                orientationValue = 5
            case UIDeviceOrientation.faceDown:
                orientationValue = 6
        }

        let screenInfo: [String:Any] = [MOMOFILER_DEVICE_SCREEN_ORIENTATION:        orientationValue]
        
        let sysVersion: String = UIDevice.current.systemVersion
        
        let deviceModelName: String = UIDevice.current.modelName
        let deviceName: String = UIDevice.current.name
        let identifierForVendor: String = UIDevice.current.identifierForVendor!.uuidString
        var printableNetworkSSID = "unknown"
        let networkSSID = fetchSSIDInfo()
        // now unwrap it
        if let unwrapped = networkSSID {
            printableNetworkSSID = unwrapped
        }
        
        var batteryInfo: [String:Any] = [:];
        
        var batteryLevel: Float {
            return UIDevice.current.batteryLevel
        }
        
        var batteryState: UIDeviceBatteryState {
            return UIDevice.current.batteryState
        }
        switch batteryState {
//            case .unknown:   //  "The battery state for the device cannot be determined."
            case .unplugged: //  "The device is not plugged into power; the battery is discharging"
                batteryInfo["isCharging"] = false;
                batteryInfo["isFull"] = false;
            case .charging:  //  "The device is plugged into power and the battery is less than 100% charged."
                batteryInfo["isCharging"] = true;
                batteryInfo["isFull"] = false;
            case .full:      //   "The device is plugged into power and the battery is 100% charged."
                batteryInfo["isCharging"] = true;
                batteryInfo["isFull"] = true;
            default:
                NSLog("----bs def");
        }
        
        batteryInfo["batteryPct"] = batteryLevel*100;
        
        
        let extras: [String:Any] = [MOMOFILER_DEVICE_PHONETYPE:                 currentRadioAccessTechnology,
                                    MOMOFILER_DEVICE_OPERATOR_MCC:              mobileCountryCode,
                                    MOMOFILER_DEVICE_OPERATOR_MCCMNC:           mobileNetworkCode,
                                    MOMOFILER_DEVICE_OPERATOR_NAME:             carrierName,
                                    MOMOFILER_DEVICE_SIM_OPERATOR_NAME:         carrierName,
                                    MOMOFILER_DEVICE_SIM_OPERATOR_MCCMNC:       mobileNetworkCode,
                                    MOMOFILER_DEVICE_DEVICE_ID:                 deviceID,
                                    MOMOFILER_DEVICE_OS_NAME:                   MOMOFILER_DEVICE_OS_NAME_IOS,
                                    MOMOFILER_DEVICE_OS_VERSION:                sysVersion,
                                    MOMOFILER_DEVICE_SDK_TYPE:                  MOMOFILER_DEVICE_SDK_TYPE_NAME,
                                    MOMOFILER_DEVICE_SDK_VERSION:               MOMOFILER_DEVICE_SDK_VERSION_N,
                                    MOMOFILER_DEVICE_MODEL_NAME:                deviceModelName,
                                    MOMOFILER_DEVICE_NAME:                      deviceName,
                                    MOMOFILER_DEVICE_IDENTIFIER_FOR_VENDOR:     identifierForVendor,
                                    MOMOFILER_DEVICE_NETWORK_SSID:              printableNetworkSSID,
                                    MOMOFILER_DEVICE_SCREEN_INFO:               screenInfo,
                                    MOMOFILER_BATTERY_INFO:                     batteryInfo,
                                    MOMOFILER_DEVICE_MAX_CPUS:                  String(format: "%f", hostInfo.pointee.max_cpus),
                                    MOMOFILER_DEVICE_AVAIL_CPUS:                String(format: "%f", hostInfo.pointee.avail_cpus),
                                    MOMOFILER_DEVICE_MEMORY_SIZE:               String(format: "%f", hostInfo.pointee.memory_size),
                                    MOMOFILER_DEVICE_MAX_MEN:                   String(format: "%f", hostInfo.pointee.max_mem),
                                    MOMOFILER_DEVICE_TOTAL_DISK_SPACE:          totalDiskSpace(),
                                    MOMOFILER_DEVICE_FREE_DISK_SPACE:           freeDiskSpace(),
                                    MOMOFILER_DEVICE_USED_DISK_SPACE:           usedDiskSpace(),
                                    MOMOFILER_DEVICE_TOTAL_DISK_SPACE_IN_BYTES: String(format: "%f", totalDiskSpaceInBytes()),
                                    MOMOFILER_DEVICE_FREE_DISK_SPACE_IN_BYTES:  String(format: "%f", freeDiskSpaceInBytes()),
                                    MOMOFILER_DEVICE_USED_DISK_SPACE_IN_BYTES:  String(format: "%f", usedDiskSpaceInBytes())]
        
        hostInfo.deallocate(capacity: 1)
        
        if UIDevice.current.isGeneratingDeviceOrientationNotifications {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        
        return extras
    }
    
    func setSdkTypeAndVersion(sdk_type: String, sdk_version: String) {
        self.MOMOFILER_DEVICE_SDK_TYPE_NAME = sdk_type
        self.MOMOFILER_DEVICE_SDK_VERSION_N = sdk_version
    }
    
    func fetchSSIDInfo() ->  String? {
        if let interfaces = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interfaces){
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                
                if let unsafeInterfaceData = unsafeInterfaceData as? Dictionary<AnyHashable, Any> {
                    return unsafeInterfaceData["SSID"] as? String
                }
            }
        }
        return nil
    }

    
    //# MARK: - Methods disk info
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
    
}
