//
//  XvTimer.swift
//  XvTimer
//
//  Created by Jason Snell on 9/5/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//
/*
 Start up timer via init.
 There are two timers, one for graphic updates, one for audio / background updates
 They need to be turned on individually
 
 XvTimer.sharedInstance.initTimer(withAppID:"com.jasonjsnell.refraktions")
 XvTimer.sharedInstance.guiClockOn = true
 XvTimer.sharedInstance.audioClockOn = true
 
 */

import Foundation

public class XvTimer:NSObject {
    
    fileprivate let debug:Bool = true
    
    //MARK: - INIT
    //singleton code
    public static let sharedInstance = XvTimer()
    override init() {
        if (debug){print("TIMER: Init")}
        super.init()
    }
    
    //MARK: TIMER VARS
    fileprivate var dispatchSourceTimer: DispatchSourceTimer? //background, fast, efficient, for audio
    fileprivate var displayLink:CADisplayLink? //foreground, for graphics

    
    //MARK: APP ID
    // called from app delegate at launch
    fileprivate var _appID:String = ""
    public func initTimer(withAppID:String) {
        _appID = withAppID
    }
    
    //MARK: - TOGGLE CLOCKS ON / OFF
    fileprivate var _guiClockOn:Bool = false
    public var guiClockOn:Bool {
        
        get { return _guiClockOn }
        set {
            self._guiClockOn = newValue
            if (debug){print("TIMER: GUI clock is now", newValue)}
            _resetGuiClock()
        }
    }
    
    fileprivate var _audioClockOn:Bool = false
    public var audioClockOn:Bool {
        
        get { return _audioClockOn }
        set {
            self._audioClockOn = newValue
            if (debug){print("TIMER: Audio clock is now", newValue)}
            _resetAudioClock()
        }
    }
    
    
    //MARK: - TICKS
    @objc internal func guiTimerTick(){
        Utils.postNotification(name: XvTimerConstants.kXvGuiClock, userInfo: nil)
    }
    
    @objc internal func audioClockTick(){
        Utils.postNotification(name: XvTimerConstants.kXvAudioClock, userInfo: nil)
    }
    
    
    
    
    //MARK: GUI / GRAPHICS CLOCK
    fileprivate func _resetGuiClock(){
        
        if (debug){print("TIMER: Reset GUI clock")}
        
        if (displayLink == nil){
            
            displayLink = CADisplayLink(target: self, selector: #selector(XvTimer.guiTimerTick))
            displayLink?.add(to: .main, forMode: RunLoop.Mode.common)
            
        } else {
            
            if (debug){ print("TIMER: GUI clock is already running") }
        }
    }
    
    
    //MARK: BACKGROUND
    fileprivate func _resetAudioClock(){
        
        if (debug){print("TIMER: Reset audio clock")}
        
        if (dispatchSourceTimer == nil){
            
            let queue = DispatchQueue(label: "com.jasonjsnell." + _appID + ".timer", attributes: .concurrent)
            //let queue = DispatchQueue(label: "com.jasonjsnell." + _appID + ".timer")
            
            dispatchSourceTimer = DispatchSource.makeTimerSource(queue: queue)
            
            let repeatInterval:DispatchTimeInterval = DispatchTimeInterval.microseconds(3000)
            let tolerance:DispatchTimeInterval = DispatchTimeInterval.microseconds(500)
            
            dispatchSourceTimer?.schedule(
                deadline: DispatchTime.now() + repeatInterval,
                repeating: repeatInterval,
                leeway: tolerance)
            
            // [weak self] only needed if you reference `self` in this closure and you want to prevent strong reference cycle
            dispatchSourceTimer?.setEventHandler { [weak self] in
                
                let _ = self?.perform(#selector(XvTimer.audioClockTick))
            }
            
            dispatchSourceTimer?.resume()
            
        } else {
            
            if (debug){ print("TIMER: Audio clock is already running") }
        }
    }
    
    //MARK: SHUTDOWN
    //called by app delegate during shutdown if bg mode is off
    public func shutdown(){
        if (debug){print("TIMER: Timer shutdown")}
        _cancelAllTimers()
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
