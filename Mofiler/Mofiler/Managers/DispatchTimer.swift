// Copyright 2015-2016 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

///
/// DispatchTimer
///
/// Much like an NSTimer from Cocoa, but implemented using dispatch queues instead.
///
class DispatchTimer: NSObject {

  /// Type for the handler block executed when a dispatch timer fires.
  ///
  /// :param: timer The timer which triggered this block
  typealias TimerHandler = (DispatchTimer) -> Void

  fileprivate let timerBlock: TimerHandler
  fileprivate let queue: DispatchQueue
  fileprivate let delay: TimeInterval

  fileprivate var wrappedBlock: (() -> Void)?
  fileprivate let source: DispatchSource

  init(delay: TimeInterval, queue: DispatchQueue, block: @escaping TimerHandler) {
    timerBlock = block
    self.queue = queue
    self.delay = delay

    self.source = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: self.queue) /*Migrator FIXME: Use DispatchSourceTimer to avoid the cast*/ as! DispatchSource

    super.init()

    let wrapper = { () -> Void in
      if self.source.isCancelled == false {
        self.source.cancel()
        self.timerBlock(self)
      }
    }

    self.wrappedBlock = wrapper
  }

  class func scheduledDispatchTimer(_ delay: TimeInterval,
    queue: DispatchQueue,
    block: @escaping TimerHandler) -> DispatchTimer {
      let dt = DispatchTimer(delay: delay, queue: queue, block: block)
      dt.schedule()
      return dt
  }

  func schedule() {
    self.reschedule()
    self.source.setEventHandler(handler: self.wrappedBlock)
    self.source.resume()
  }

  func reschedule() {
    let start = DispatchTime.now() + Double(Int64(self.delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

    // Leeway is 10% of timer delay
//    self.source.setTimer(start: start, interval: DispatchTime.distantFuture,
//      leeway: UInt64((self.delay / 10.0) * Double(NSEC_PER_SEC)))
    
    let timer = DispatchSource.makeTimerSource(queue: self.queue)
    timer.scheduleRepeating(deadline: start, interval: self.delay, leeway: .seconds(Int(UInt64((self.delay / 10.0) * Double(NSEC_PER_SEC)))))

    
    
  }

  func suspend() {
    self.source.suspend()
  }

  func resume() {
    self.source.resume()
  }

  func cancel() {
    self.source.cancel()
  }

}
