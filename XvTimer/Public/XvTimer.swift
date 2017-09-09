//
//  XvTimer.swift
//  XvTimer
//
//  Created by Jason Snell on 9/5/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

public class XvTimer:NSObject {
    
    
    
    
    
    //MARK: - VARS
    
    //MARK: APP ID
    // called from app delegate at launch
    
    fileprivate var _appID:String = ""
    
    //MARK: MODE
    fileprivate var _foregroundMode:Bool = true
    public var foregroundMode:Bool {
        get { return _foregroundMode }
        set {
            self._foregroundMode = newValue
            if (debug){print("TIMER: Foreground mode is now", newValue)}
            reset() // reset each time the mode is changed
        }
    }
    
    //MARK: TIMER VARS
    fileprivate var dispatchSourceTimer: DispatchSourceTimer? //background, fast, efficient
    fileprivate var displayLink:CADisplayLink? //foreground, good with graphics
    
    fileprivate let debug:Bool = true
    
    
    //MARK: - INIT
    //singleton code
    public static let sharedInstance = XvTimer()
    override init() {
        if (debug){print("METRONOME: Init")}
    }
    
    public func initTimer(withAppID:String) {
        _appID = withAppID
    }
    
    //MARK: - TICK
    internal func timerTick(){
        Utils.postNotification(name: XvTimerConstants.kXvTimerTick, userInfo: nil)
    }
    
    
    //MARK: - RESET
    //called internally
    fileprivate func reset(){
        
        if (debug){print("TIMER: Reset")}
        
        if (_foregroundMode){
            
            //if the foreground timer is not running....
            if (displayLink == nil){
                
                //cancel all
                _cancelAllTimers()
                
                //and reset foreground timer
                _resetForegroundTimer()
                
            } else {
                
                if (debug){ print("TIMER: Foreground timer is already running") }
            }
            
        } else {
            
            //if the background timer is not running....
            if (dispatchSourceTimer == nil){
                
                //cancel all
                _cancelAllTimers()
                
                //and reset background timer
                _resetBackgroundTimer()
                
            } else {
                
                if (debug){ print("TIMER: Background timer is already running") }
            }
        }
    }
    
    
    
    
    //MARK: FOREGROUND
    fileprivate func _resetForegroundTimer(){
        
        if (debug){print("TIMER: Reset foreground timer")}
        
        displayLink = CADisplayLink(target: self, selector: #selector(XvTimer.timerTick))
        displayLink?.add(to: .main, forMode: .commonModes)
    }
    
    
    //MARK: BACKGROUND
    fileprivate func _resetBackgroundTimer(){
        
        if (debug){print("TIMER: Reset background timer")}
        
        let queue = DispatchQueue(label: "com.jasonjsnell." + _appID + ".timer", attributes: .concurrent)
        
        dispatchSourceTimer = DispatchSource.makeTimerSource(queue: queue)
        
        dispatchSourceTimer?.scheduleRepeating(
            deadline: .now(),
            interval: .milliseconds(10),
            leeway: .milliseconds(1))
        
        dispatchSourceTimer?.setEventHandler { [weak self] in // `[weak self]` only needed if you reference `self` in this closure and you want to prevent strong reference cycle
            
            let _ = self?.perform(#selector(XvTimer.timerTick))
        }
        
        dispatchSourceTimer?.resume()
    }
    
    //cancel
    fileprivate func _cancelAllTimers(){
        
        //stop all timers
        dispatchSourceTimer?.cancel()
        dispatchSourceTimer = nil
        displayLink?.invalidate()
        displayLink = nil
        
    }

}

