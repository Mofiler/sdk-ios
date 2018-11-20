//
//  MOGenericManager.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/7/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import Foundation
import UIKit

public class MOGenericManager : NSObject {
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillHibernateToBackground(_:)), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }
    
    @objc func applicationWillEnterForeground(_ notification: Notification) {
        //Do Nothing
    }
    
    @objc func applicationWillHibernateToBackground(_ notification: Notification) {
        //Do Nothing
    }
    
    @objc func applicationWillTerminate(_ notification: Notification) {
        //Do Nothing
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }
}
