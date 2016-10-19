//
//  AppDelegate.swift
//  MofilerAppSwift
//
//  Created by Fernando Chamorro on 10/11/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import UIKit
import Mofiler

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MofilerDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let mof = Mofiler.sharedInstance
        
        mof.initializeWith(appKey: "MY-­APPKEY-­HERE-IOS", appName: "MyIosTestApplication", identity: ["username" : "johndoe"])
        mof.delegate = self
        mof.url = "mofiler.com"
        mof.addIdentity(identity: ["name":"john doe"])
        mof.addIdentity(identity: ["email":"john@doe.com"])
        mof.useLocation = false
        mof.useVerboseContext = true
        
        mof.injectValue(newValue: ["mykey1":"myvalue1"])
        mof.injectValue(newValue: ["mykey2":"myvalue2"], expirationDateInMilliseconds: 100000000.0)
        mof.injectValue(newValue: ["mykey3":"myvalue3"])
        mof.injectValue(newValue: ["mykey4":"myvalue4"], expirationDateInMilliseconds: 100000000.0)
        mof.injectValue(newValue: ["mykey5":"myvalue5"])
        mof.injectValue(newValue: ["mykey6":"myvalue6"])
        mof.injectValue(newValue: ["mykey7":"myvalue7"], expirationDateInMilliseconds: 100000000.0)
        mof.injectValue(newValue: ["mykey8":"myvalue8"])
        mof.injectValue(newValue: ["mykey9":"myvalue9"])
        mof.injectValue(newValue: ["mykey10":"myvalue10"])
        mof.injectValue(newValue: ["mykey11":"myvalue11"])
        mof.injectValue(newValue: ["mykey12":"myvalue12"])
        mof.injectValue(newValue: ["mykey13":"myvalue13"])
        
        
        mof.flushDataToMofiler()
        
        mof.getValue(key: "mykey1", identityKey: "username", identityValue: "johndoe")
        
        mof.getValue(key: "mykey1", identityKey: "username", identityValue: "johndoe") { (result, error) in
            print(result)
        }
        
        
        return true
    }
    
    //# MARK: - MofilerDelegate
    public func responseValue(key: String, identityKey: String, identityValue: String, value: [String : Any]) {
        print(value)
    }
    
    func errorOcurred(error: String, userInfo: [String : String]) {
        print(error)
    }

}

