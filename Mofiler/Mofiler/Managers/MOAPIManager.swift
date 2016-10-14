//
//  MOAPIManager.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/7/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import Alamofire
import BoltsSwift

class MOAPIManager: MOGenericManager /*,  MTDiskCacheProtocol */ {

    let MO_APIMANAGER_COOKIES    = "MO_APIMANAGER_COOKIES"
    let MO_API_URL               = ""
    let MO_API_DEFAULT_TIMEOUT   = 30.0
    let MO_API_QUEUENAME         = "MOAPIMANAGER"
    let alamoFire                = Alamofire.SessionManager.default
    
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
    

    func queueAPIOperationForParameters(params: [String:AnyObject]) -> Task<AnyObject> {
        
        var parameters = params
        let successful = TaskCompletionSource<AnyObject>()
        
        apiQueue().async(group: apiGroup()) { () -> Void in
            
            var requestAction = ""
            if let val: String = parameters["action"] as? String {
                requestAction = val
                parameters["action"] = nil
            }
            
            var requestMethod = Alamofire.HTTPMethod.get
            
            if let val: String = parameters["method"] as? String {
                parameters["method"] = nil
                if val == "POST" {
                    requestMethod = Alamofire.HTTPMethod.post
                } else if val == "PUT" {
                    requestMethod = Alamofire.HTTPMethod.put
                }
            }
            
            var urlBase = ""
            if let val: String = parameters["urlBase"] as? String {
                urlBase = val
                parameters["urlBase"] = nil
            }
            
            var appKey = ""
            if let val: String = parameters["appKey"] as? String {
                appKey = val
                parameters["appKey"] = nil
            }
            
            var appName = ""
            if let val: String = parameters["appName"] as? String {
                appName = val
                parameters["appName"] = nil
            }
            
            var installID = ""
            if let val = UserDefaults.standard.object(forKey: "MOMOFILER_APPLICATION_INSTALLID") as? String {
                installID = val
            }
            
            var sessionID = ""
            if let val = UserDefaults.standard.object(forKey: "MOMOFILER_SESSION_ID") as? String {
                sessionID = val
            }

            let headers = ["Accept" : "application/json",
                           "Content­type" : "application/json",
                           "X­Mofiler­ApiVersion" : "0.1",
                           "X­Mofiler­AppKey" : appKey,
                           "X­Mofiler­AppName" : appName,
                           "X­Mofiler­InstallID" : installID,
                           "X­Mofiler­SessionID" : sessionID]
            
            let url = String(format: "%@%@", urlBase, requestAction)
            
            Alamofire.request(url, method: requestMethod, parameters: parameters, encoding: URLEncoding.default, headers: headers).responseJSON {
                data in
                if data.result.isSuccess {
                    successful.set(result: data.result.value as AnyObject)
                } else if let dataError = data.result.error {
                    successful.set(error: dataError)
                } else {
                    successful.set(error: NSError(domain: "Unexpected error", code: 100, userInfo: nil))
                }
            }
            
        }
        return successful.task
    }
    
    
    func uploadValues(urlBase: String, appKey: String, appName: String, values:[String:String]) -> Task<AnyObject> {
        
        var parameters: [String:AnyObject]  = [:]
        
        parameters["action"]                = "api/values" as AnyObject?
        parameters["method"]                = "POST" as AnyObject?
        parameters["urlBase"]               = urlBase as AnyObject?
        parameters["appKey"]                = appKey as AnyObject?
        parameters["appName"]               = appName as AnyObject?
        
        parameters["values"]                = values as AnyObject?
        
        return queueAPIOperationForParameters(params: parameters)
    }
    
    
    func getValue(identityKey:String, identityValue:String, keyToRetrieve:String, urlBase: String, appKey: String, appName: String, device: String) -> Task<AnyObject> {
        
        var parameters: [String:AnyObject]  = [:]
        
        let url = String(format: "api/values/%@/%@/%@/%@", device, identityKey, identityValue, keyToRetrieve)
        parameters["action"]                = url as AnyObject?
        parameters["method"]                = "GET" as AnyObject?
        parameters["urlBase"]               = urlBase as AnyObject?
        parameters["appKey"]                = appKey as AnyObject?
        parameters["appName"]               = appName as AnyObject?
        
        return queueAPIOperationForParameters(params: parameters)
    }



}
