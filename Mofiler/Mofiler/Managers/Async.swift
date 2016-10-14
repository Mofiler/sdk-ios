//
//  Async.swift
//  Mofiler
//
//  Created by Fernando Chamorro on 10/14/16.
//  Copyright © 2016 MobileTonic. All rights reserved.
//

import Foundation

func performBlock(_ block: @escaping ()->()) {
    DispatchQueue.global().async(execute: block)
}
func performBlock(afterDelayInSeconds: Double, block: @escaping ()->()) {
    let popTime = DispatchTime.now() + Double(Int64(afterDelayInSeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC);
    DispatchQueue.global().asyncAfter(deadline: popTime, execute: block);
}
func performBlockOnMainQueue(_ block: @escaping ()->()) {
    DispatchQueue.main.async(execute: block)
}
func performBlockOnMainQueue(afterDelayInSeconds: Double, block: @escaping ()->()) {
    let popTime = DispatchTime.now() + Double(Int64(afterDelayInSeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC);
    DispatchQueue.main.asyncAfter(deadline: popTime, execute: block);
}
