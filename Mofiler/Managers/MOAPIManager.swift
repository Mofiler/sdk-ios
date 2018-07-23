//
//  MOAPIManager.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/7/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

class MOAPIManager: MOGenericManager {

    let MO_API_DEFAULT_TIMEOUT   = 30.0
    let MO_API_QUEUENAME         = "MOAPIMANAGER"
    
    static let sharedInstance = MOAPIManager()
    static var initialized = false
    
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    var dataTask: URLSessionDataTask?
    
    override init() {
        super.init()
        if (!MOAPIManager.initialized) {
            
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = MO_API_DEFAULT_TIMEOUT
            configuration.timeoutIntervalForResource = MO_API_DEFAULT_TIMEOUT
            
            MOAPIManager.initialized = true;
        }
    }
    
    func createUrlRequest(url: URL, appKey: String, appName: String) -> URLRequest {
        
        var urlRequest = URLRequest(url: url)
        
        if let installID = UserDefaults.standard.object(forKey: Mofiler.sharedInstance.MOMOFILER_APPLICATION_INSTALLID) as? String {
            urlRequest.addValue(installID, forHTTPHeaderField: "x-mofiler-installid")
        }
        
        if let sessionID = UserDefaults.standard.object(forKey: Mofiler.sharedInstance.MOMOFILER_SESSION_ID) as? String {
            urlRequest.addValue(sessionID, forHTTPHeaderField: "x-mofiler-sessionid")
        }
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("0.1", forHTTPHeaderField: "x-mofiler-apiversion")
        urlRequest.addValue(appKey, forHTTPHeaderField: "x-mofiler-appkey")
        urlRequest.addValue(appName, forHTTPHeaderField: "x-mofiler-appname")
        urlRequest.addValue("1", forHTTPHeaderField: "x-mofiler-noiselevel")
        

        return urlRequest
    }
    
    
    func getValue(identityKey:String, identityValue:String, keyToRetrieve:String, urlBase: String, appKey: String, appName: String, device: String, callback: @escaping (Any?, String?) -> Void) {
        
        guard let url = URL(string: String(format: "https://%@/api/values/%@/%@/%@/%@", urlBase, device, identityKey, identityValue, keyToRetrieve)) else {
            callback(nil, "Error: cannot create URL")
            return
        }
        
        let urlRequest = createUrlRequest(url: url, appKey: appKey, appName: appName)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in

            guard error == nil else {
                callback(nil, "Error, get api.")
                return
            }
            
            guard let responseData = data else {
                callback(nil, "Error: did not receive data")
                return
            }
            
            do {
                guard let result = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                    callback(nil, "error trying to convert data to JSON")
                    return
                }
                
                callback(result as Any?, nil)
            } catch  {
                callback(nil, "error trying to convert data to JSON")
                return
            }
            
            
        })
        
        task.resume()
    }
    
    

  

    func uploadValues(urlBase: String, appKey: String, appName: String, data: [String:Any], callback: @escaping (Any?, String?) -> Void) {
        
        do {

            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            
            guard let url = URL(string: String(format: "https://%@/api/values/", urlBase)) else {
                callback(nil, "Error: cannot create URL")
                return
            }
            
            var urlRequest = createUrlRequest(url: url, appKey: appKey, appName: appName)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = jsonData
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            
            let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in

                guard error == nil else {
                    callback(nil, "Error, post api.")
                    return
                }
                
                guard let responseData = data else {
                    callback(nil, "Error: did not receive data")
                    return
                }
                
                do {
    
                    guard let result = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                        callback(nil, "error trying to convert data to JSON")
                        return
                    }
                    
                    callback(result as Any?, nil)
                } catch  {
                    callback(nil, "error trying to convert data to JSON")
                    return
                }
            })
            
            task.resume()
            
        } catch {
          
        }
        
    }
    
    
}
