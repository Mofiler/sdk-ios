//
//  MOAPIManager.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/7/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

//import Alamofire
//import BoltsSwift

class MOAPIManager: MOGenericManager /*,  MTDiskCacheProtocol */ {

    let MO_APIMANAGER_COOKIES    = "MO_APIMANAGER_COOKIES"
    let MO_API_URL               = ""
    let MO_API_DEFAULT_TIMEOUT   = 30.0
    let MO_API_QUEUENAME         = "MOAPIMANAGER"
    
    //var alamoFire                = Alamofire.SessionManager.default
    
    static let sharedInstance = MOAPIManager()
    static var initialized = false
    static var group: DispatchGroup?
    static var queue: DispatchQueue?
    
    
//    func loadDataFromCache(_ data: [String : AnyObject], diskCache: MODiskCache) {
//        let cookies: Array<AnyObject> = data[MO_APIMANAGER_COOKIES] as! Array<AnyObject>
//        let cookieStorage = HTTPCookieStorage.shared
//        for cookie in cookies {
//            if let cookie: HTTPCookie = cookie as? HTTPCookie { cookieStorage.setCookie(cookie) }
//        }
//    }

//    func dataToCacheForDiskCache(_ diskCache: MTDiskCache) -> [String : AnyObject]? {
//        if let cookie = HTTPCookieStorage.shared.cookies {
//            return [MO_APIMANAGER_COOKIES:cookie as AnyObject]
//        }
//        return [MO_APIMANAGER_COOKIES:"" as AnyObject]
//    }

    override init() {
        super.init()
        if (!MOAPIManager.initialized) {
            //MODiskCache.sharedInstance.registerForDiskCaching("ApiManagerCache", object: self)
            
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = MO_API_DEFAULT_TIMEOUT
            configuration.timeoutIntervalForResource = MO_API_DEFAULT_TIMEOUT

//            alamoFire = Alamofire.SessionManager(configuration: configuration)
            
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
