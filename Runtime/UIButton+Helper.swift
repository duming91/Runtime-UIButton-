//
//  UIButton+Helper.swift
//  Runtime
//
//  Created by 董亚珣 on 16/6/14.
//  Copyright © 2016年 snow. All rights reserved.
//

import UIKit
import ObjectiveC.runtime

let defaultDuration : NSTimeInterval = 3.0

extension UIButton {
    
    private struct AssociatedKeys {
        static var clickDurationTime = "my_clickDurationTime"
        static var isIgnoreEvent = "my_isIgnoreEvent"
    }
    
    // 点击间隔时间
    var clickDurationTime : NSTimeInterval {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.clickDurationTime, newValue as NSTimeInterval, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            
            if let clickDurationTime = objc_getAssociatedObject(self, &AssociatedKeys.clickDurationTime) as? NSTimeInterval {
                return clickDurationTime
            }
            
            return defaultDuration
        }
    }
    
    // 是否忽视点击事件
    var isIgnoreEvent : Bool {
        
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isIgnoreEvent, newValue as Bool, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            
            if let isIgnoreEvent = objc_getAssociatedObject(self, &AssociatedKeys.isIgnoreEvent) as? Bool {
                return isIgnoreEvent
            }
            
            return false
        }
    }
    
    // swift现不支持重写+load方法
    override public class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        if self !== UIButton.self {
            return
        }

        dispatch_once(&Static.token) {
            
            let originalSelector = #selector(UIButton.sendAction(_:to:forEvent:))
            let swizzledSelector = #selector(UIButton.my_sendAction(_:to:forEvent:))
            
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            // 运行时为类添加我们自己写的my_sendAction(_:to:forEvent:)
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod {
                // 如果添加成功，则交换方法
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                // 如果添加失败，则交换方法的具体实现
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
            
        }
    }
    
    // SwizzledMethod
    func my_sendAction(action: Selector, to target: AnyObject?, forEvent event: UIEvent?) {
        
        if self.isKindOfClass(UIButton) {
            
            clickDurationTime = clickDurationTime == 0 ? defaultDuration : clickDurationTime
            
            if isIgnoreEvent {
                return
            } else if clickDurationTime > 0 {
                isIgnoreEvent = true
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(clickDurationTime) * Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.isIgnoreEvent = false
                }
                
                my_sendAction(action, to: target, forEvent: event)
            }
        } else {
            my_sendAction(action, to: target, forEvent: event)
        }
    }
    
}



