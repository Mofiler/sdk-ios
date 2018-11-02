//
//  MODiskCache.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/17/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import Foundation

protocol MODiskCacheProtocol {
    func dataToCacheForDiskCache(_ diskCache: MODiskCache) -> [String:Any]?
    func loadDataFromCache(_ data: [String:Any], diskCache: MODiskCache)
}

class MODiskCache : NSObject {
    
    static let sharedInstance = MODiskCache()
    static var objectSingletonInitialized = false;
    
    fileprivate var registeredObjects: Dictionary<String, MODiskCacheProtocol> = Dictionary<String, MODiskCacheProtocol>()
    fileprivate var loadedCacheData: Dictionary<String, Dictionary<String, Any>> = Dictionary<String, Dictionary<String, Any>>()
    fileprivate var isSaving = false
    
    override init() {
        super.init()
        
        if (!MODiskCache.objectSingletonInitialized) {
            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillHibernateToBackground(_:)), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
            
            loadCacheFromDisk()
            MODiskCache.objectSingletonInitialized = true;
        }
    }
    
    deinit {
        if (!MODiskCache.objectSingletonInitialized) {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        }
    }
    
    func registerForDiskCaching(_ key: String, object: MODiskCacheProtocol) {
        if (registeredObjects[key] == nil) {
            registeredObjects[key] = object
            
            if let cachedData = loadedCacheData[key] {
                object.loadDataFromCache(cachedData, diskCache: self)
                loadedCacheData.removeValue(forKey: key)
            }
        }
    }
    
    func diskCacheFilePath() -> String {
        let fileName = "/cache.plist"
        let baseFileDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return baseFileDir + fileName
    }
    
    func loadCacheFromDisk() {
        if let cachedData = NSKeyedUnarchiver.unarchiveObject(withFile: diskCacheFilePath()) as? Dictionary<String, Dictionary<String, Any>>{
            loadedCacheData = cachedData
        }
    }
    
    func saveCacheToDisk() {
        if (!isSaving) {
            isSaving = true
            var allDataToCache: Dictionary<String, Dictionary<String, Any>> = [:]
            
            for (key, object) in registeredObjects {
                if let dataToCache = object.dataToCacheForDiskCache(self) {
                    allDataToCache[key] = dataToCache
                }
            }
            
            NSKeyedArchiver.archiveRootObject(allDataToCache, toFile: diskCacheFilePath())
            isSaving = false
        }
    }
    
    @objc func applicationWillHibernateToBackground(_ notification: Notification) {
        saveCacheToDisk()
    }
    
    @objc func applicationWillTerminate(_ notification: Notification) {
        saveCacheToDisk()
    }
}
