//
//  MOMofiler.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/11/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import Foundation

class MOMofiler: MOBaseModel {
    
    let MOMOFILER_APP_KEY               = "MOMOFILER_APP_KEY"
    let MOMOFILER_APP_NAME              = "MOMOFILER_APP_NAME"
    let MOMOFILER_URL                   = "MOMOFILER_URL"
    let MOMOFILER_IDENTITIES            = "MOMOFILER_IDENTITIES"
    let MOMOFILER_USE_LOCATION          = "MOMOFILER_USE_LOCATION"
    let MOMOFILER_USE_VERBOSE_CONTEXT   = "MOMOFILER_USE_VERBOSE_CONTEXT"
    let MOMOFILER_VALUES                = "MOMOFILER_VALUES"

    var appKey:String?
    var appName:String?
    var url:String?
    var identities:Array<[String:String]>?
    var useLocation:Bool?
    var useVerboseContext:Bool?
    var values:Array<[String:String]>?
    
    override init(jsonData: [String:AnyObject]) {
        super.init(jsonData: jsonData)
    }

    required  init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        appKey              = validateStringField(field: aDecoder.decodeObject(forKey: MOMOFILER_APP_KEY))
        appName             = validateStringField(field: aDecoder.decodeObject(forKey: MOMOFILER_APP_NAME))
        url                 = validateStringField(field: aDecoder.decodeObject(forKey: MOMOFILER_URL))
        identities          = validateArrayField(field: aDecoder.decodeObject(forKey: MOMOFILER_IDENTITIES))
        useLocation         = validateBoolField(field: aDecoder.decodeBool(forKey: MOMOFILER_USE_LOCATION))
        useVerboseContext   = validateBoolField(field: aDecoder.decodeBool(forKey: MOMOFILER_USE_VERBOSE_CONTEXT))
        values              = validateArrayField(field: aDecoder.decodeObject(forKey: MOMOFILER_VALUES))

    }

    override func encode(with aCoder: NSCoder) {

        if let appKey = appKey {
            aCoder.encode(appKey, forKey: MOMOFILER_APP_KEY)
        }
        if let appName = appName {
            aCoder.encode(appName, forKey: MOMOFILER_APP_NAME)
        }
        if let url = url {
            aCoder.encode(url, forKey: MOMOFILER_URL)
        }
        if let identities = identities {
            aCoder.encode(identities, forKey: MOMOFILER_IDENTITIES)
        }
        if let useLocation = useLocation {
            aCoder.encode(useLocation, forKey: MOMOFILER_USE_LOCATION)
        }
        if let useVerboseContext = useVerboseContext {
            aCoder.encode(useVerboseContext, forKey: MOMOFILER_USE_VERBOSE_CONTEXT)
        }
        if let values = values {
            aCoder.encode(values, forKey: MOMOFILER_VALUES)
        }
    }

    override func updateWithJSONData(jsonData: [String : AnyObject]) {
        appKey              = validateStringField(field: jsonData["nombre"])
        appName             = validateStringField(field: jsonData["nombre"])
        url                 = validateStringField(field: jsonData["nombre"])
        identities          = validateArrayField(field: jsonData["nombre"])
        useLocation         = validateBoolField(field: jsonData["nombre"])
        useVerboseContext   = validateBoolField(field: jsonData["nombre"])
        values              = validateArrayField(field: jsonData["nombre"])
    }

}
