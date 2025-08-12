//
//  MediaKeyController.swift
//  AirPodsMicHelper
//
//  Created on 2025-08-12.
//  Copyright © 2025 Rahnas. All rights reserved.
//

import Foundation
import AVFoundation
import CoreAudio

protocol MediaKeyControllerDelegate: AnyObject {
    func mediaKeyController(_ controller: MediaKeyController, didDetectAirPodsButtonPress isMuted: Bool)
}

class MediaKeyController: NSObject {
    weak var delegate: MediaKeyControllerDelegate?
    private var audioApplication: AVAudioApplication?
    
    override init() {
        super.init()
        setupAudioApplication()
    }
    
    // MARK: - Apple's Official AVAudioApplication Setup
    private func setupAudioApplication() {
        NSLog("[MediaKeyController] 🎵 Setting up AVAudioApplication for AirPods button detection...")
        
        // Check if we're running on macOS 14.0+ (required for AVAudioApplication)
        if #available(macOS 14.0, *) {
            do {
                audioApplication = try AVAudioApplication.shared
                
                // Configure the Input Mute State Change handler (macOS only)
                try audioApplication?.setInputMuteStateChangeHandler { [weak self] isMuted in
                    NSLog("[MediaKeyController] 🎧 AirPods button pressed - Mute state: %@", isMuted ? "MUTED" : "UNMUTED")
                    
                    // Notify delegate about the mute state change
                    DispatchQueue.main.async {
                        self?.delegate?.mediaKeyController(self!, didDetectAirPodsButtonPress: isMuted)
                    }
                    
                    // Return true to indicate we handled the mute state change
                    return true
                }
                
                NSLog("[MediaKeyController] ✅ AVAudioApplication setup completed successfully")
                
            } catch {
                NSLog("[MediaKeyController] ❌ Failed to setup AVAudioApplication: %@", error.localizedDescription)
                print("[MediaKeyController] Error: \(error)")
            }
        } else {
            NSLog("[MediaKeyController] ❌ AVAudioApplication requires macOS 14.0+")
            print("[MediaKeyController] AVAudioApplication requires macOS 14.0+")
        }
    }
    
    // MARK: - Core Audio Muting (Apple's recommended approach)
    func setSystemMute(_ isMuted: Bool) {
        NSLog("[MediaKeyController] 🔊 Setting system mute to: %@", isMuted ? "MUTED" : "UNMUTED")
        
        // Optional: let CoreAudio mute your input for you (macOS only)
        // Define the Core Audio property
        var inputMutePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessInputMute,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Enable this property when you want to mute your input
        var muteValue: UInt32 = isMuted ? 1 : 0 // 1 = muted, 0 = unmuted
        let result = AudioObjectSetPropertyData(
            kAudioObjectSystemObject,
            &inputMutePropertyAddress,
            0,
            nil,
            UInt32(MemoryLayout.size(ofValue: muteValue)),
            &muteValue
        )
        
        if result == noErr {
            NSLog("[MediaKeyController] ✅ Successfully set system mute to: %@", isMuted ? "MUTED" : "UNMUTED")
        } else {
            NSLog("[MediaKeyController] ❌ Failed to set system mute. Error code: %d", result)
        }
    }
    
    // MARK: - Control Methods
    func startDetection() {
        NSLog("[MediaKeyController] 🚀 Starting AirPods button detection...")
        // AVAudioApplication detection is automatically active once set up
    }
    
    func stop() {
        NSLog("[MediaKeyController] ⏹️ Stopping AirPods button detection...")
        
        if #available(macOS 14.0, *) {
            do {
                // Remove the input mute state change handler
                try audioApplication?.setInputMuteStateChangeHandler(nil)
                NSLog("[MediaKeyController] ✅ Input mute state handler removed")
            } catch {
                NSLog("[MediaKeyController] ❌ Error removing handler: %@", error.localizedDescription)
            }
        }
        
        audioApplication = nil
    }
    
    deinit {
        stop()
    }
}

// MARK: - Debug Methods

extension MediaKeyController {
    func getStatus() -> String {
        var status = "MediaKeyController Status:\n"
        
        if audioApplication != nil {
            status += "AVAudioApplication: Active\n"
            status += "Listening for: AirPods mute button presses\n"
            status += "Method: Apple's official setInputMuteStateChangeHandler\n"
        } else {
            status += "AVAudioApplication: Not initialized\n"
        }
        
        return status
    }
}
