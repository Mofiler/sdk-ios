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
    static var group: DispatchGroup?
    static var queue: DispatchQueue?
    
    
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
    
    func getValue(identityKey:String, identityValue:String, keyToRetrieve:String, urlBase: String, appKey: String, appName: String, device: String, callback: @escaping (AnyObject?, String?) -> Void) {
    
        // Set up the URL request
        let urlString = String(format: "%@/api/values/%@/%@/%@/%@", urlBase, device, identityKey, identityValue, keyToRetrieve)
        guard let url = URL(string: urlString) else {
            callback(nil, "Error: cannot create URL")
            return
        }
        var urlRequest = URLRequest(url: url)
        

        guard let installID = UserDefaults.standard.object(forKey: "MOMOFILER_APPLICATION_INSTALLID") as? String else {
            callback(nil, "Error: cannot installID")
            return
        }
        
        guard let sessionID = UserDefaults.standard.object(forKey: "MOMOFILER_SESSION_ID") as? String else {
            callback(nil, "Error: cannot sessionID")
            return
        }
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("0.1", forHTTPHeaderField: "X­Mofiler­ApiVersion")
        urlRequest.addValue(appKey, forHTTPHeaderField: "X­Mofiler­AppKey")
        urlRequest.addValue(appName, forHTTPHeaderField: "X­Mofiler­AppName")
        urlRequest.addValue(installID, forHTTPHeaderField: "X­Mofiler­InstallID")
        urlRequest.addValue(sessionID, forHTTPHeaderField: "X­Mofiler­SessionID")
        
        
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // make the request
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            print(error)
            print(response)
            
            // check for any errors
            guard error == nil else {
                callback(nil, "Error")
                return
            }
            
            // make sure we got data
            guard let responseData = data else {
                callback(nil, "Error: did not receive data")
                return
            }
            
            // parse the result as JSON, since that's what the API provides
            do {
                guard let result = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                    callback(nil, "error trying to convert data to JSON")
                    return
                }
                
                callback(result as AnyObject?, nil)
            } catch  {
                callback(nil, "error trying to convert data to JSON")
                return
            }
            
            
        })
        
        task.resume()
    }
  
    func uploadValues(urlBase: String, appKey: String, appName: String, values:Array<[String:String]>, callback: @escaping (AnyObject?, String?) -> Void) {
        
        var parameters: [String:AnyObject]  = [:]
        parameters["values"]                = values as AnyObject?
        //TODO
        
        do {
            
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
            // Set up the URL request
            let urlString = String(format: "%@/api/values", urlBase)
            guard let url = URL(string: urlString) else {
                callback(nil, "Error: cannot create URL")
                return
            }
            var urlRequest = URLRequest(url: url)
            
            guard let installID = UserDefaults.standard.object(forKey: "MOMOFILER_APPLICATION_INSTALLID") as? String else {
                callback(nil, "Error: cannot installID")
                return
            }
            
            guard let sessionID = UserDefaults.standard.object(forKey: "MOMOFILER_SESSION_ID") as? String else {
                callback(nil, "Error: cannot sessionID")
                return
            }
            
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("0.1", forHTTPHeaderField: "X­Mofiler­ApiVersion")
            urlRequest.addValue(appKey, forHTTPHeaderField: "X­Mofiler­AppKey")
            urlRequest.addValue(appName, forHTTPHeaderField: "X­Mofiler­AppName")
            urlRequest.addValue(installID, forHTTPHeaderField: "X­Mofiler­InstallID")
            urlRequest.addValue(sessionID, forHTTPHeaderField: "X­Mofiler­SessionID")
            
            
            // set up the session
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = jsonData
            
            
            // make the request
            let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                print(error)
                print(response)
                
                // check for any errors
                guard error == nil else {
                    callback(nil, "Error")
                    return
                }
                
                // make sure we got data
                guard let responseData = data else {
                    callback(nil, "Error: did not receive data")
                    return
                }
                
                // parse the result as JSON, since that's what the API provides
                do {
                    guard let todo = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                        callback(nil, "error trying to convert data to JSON")
                        return
                    }
                    
                    // now we have the todo, let's just print it to prove we can access it
                    print("The todo is: " + todo.description)
                    
                    
                } catch  {
                    callback(nil, "error trying to convert data to JSON")
                    return
                }
                
            })
            
            task.resume()
            
        } catch {
            print(error)
        }
        
    }
}
