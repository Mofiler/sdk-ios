//
//  MOAPIManager.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/7/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//


class MOAPIManager: MOGenericManager /*,  MTDiskCacheProtocol */ {

    let MO_APIMANAGER_COOKIES    = "MO_APIMANAGER_COOKIES"
    let MO_API_URL               = ""
    let MO_API_DEFAULT_TIMEOUT   = 30.0
    let MO_API_QUEUENAME         = "MOAPIMANAGER"
    

    
    static let sharedInstance = MOAPIManager()
    static var initialized = false
    static var group: DispatchGroup?
    static var queue: DispatchQueue?
    
    
    override init() {
        super.init()
        if (!MOAPIManager.initialized) {

            
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = MO_API_DEFAULT_TIMEOUT
            configuration.timeoutIntervalForResource = MO_API_DEFAULT_TIMEOUT
            
            MOAPIManager.initialized = true;
        }
    }
    
    func apiGroup() -> DispatchGroup {
        if MOAPIManager.group == nil {
            MOAPIManager.group = DispatchGroup();
        }
        return MOAPIManager.group!
    }
    
    func apiQueue() -> DispatchQueue {
        if MOAPIManager.queue == nil {
            MOAPIManager.queue = DispatchQueue(label: MO_API_QUEUENAME, attributes: DispatchQueue.Attributes.concurrent)
        }
        return MOAPIManager.queue!
    }
    
    func getApiURL() ->String{
        return MO_API_URL
    }


}
