//
//  MOBaseModel.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/11/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import Foundation

class MOBaseModel: NSObject, NSCoding {
    
    required init?(coder aDecoder: NSCoder) { /*Do nothing*/ }
    
    func encode(with aCoder: NSCoder) { /*Do nothing*/ }
    
    init(jsonData: [String:AnyObject]) {
        super.init()
        updateWithJSONData(jsonData: jsonData)
    }
    
    func updateWithJSONData(jsonData: [String:AnyObject]) { /*Do nothing*/ }
    
    func validateStringField(field: Any?) -> String? {
        if let field = field , field is String {
            return field as? String
        }
        return nil
    }

    func validateArrayField(field: Any?) -> Array<[String:String]>? {
        if let field = field , field is Array<[String:String]> {
            return field as? Array<[String:String]>
        }
        return nil
    }
    
    func validateBoolField(field: Any?) -> Bool? {
        if let field = field , field is Bool {
            return field as? Bool
        }
        return nil
    }
}
