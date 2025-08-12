//
//  AudioController.swift
//  AirPodsMicHelper
//
//  Created on 2025-08-11.
//  Copyright © 2025 Rahnas. All rights reserved.
//

import Foundation
import AVFoundation
import CoreAudio
import AudioToolbox

class AudioController {
    private var currentMuteState: Bool = false
    private var audioObjectPropertyAddress: AudioObjectPropertyAddress
    private var avAudioApplication: AVAudioApplication?
    
    init() {
        // Initialize Core Audio property address for global input mute
        audioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessInputMute,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        setupAudioApplication()
        refreshMuteState()
    }
    
    private func setupAudioApplication() {
        if #available(macOS 14.0, *) {
            // For macOS Sonoma (14+), use AVAudioApplication for AirPods gesture support
            do {
                avAudioApplication = AVAudioApplication.shared
                
                // Register for input mute state change notifications
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleInputMuteStateChange),
                    name: AVAudioApplication.inputMuteStateChangeNotification,
                    object: nil
                )
                
                print("[AudioController] AVAudioApplication setup completed for macOS Sonoma+")
            } catch {
                print("[AudioController] Failed to setup AVAudioApplication: \(error)")
            }
        } else {
            print("[AudioController] Running on macOS < 14.0, using Core Audio only")
        }
    }
    
    @objc private func handleInputMuteStateChange() {
        if #available(macOS 14.0, *) {
            refreshMuteState()
            
            // Post notification for UI updates
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .audioStateChanged, object: nil)
            }
            
            print("[AudioController] Input mute state changed via AirPods gesture")
        }
    }
    
    var isMuted: Bool {
        return currentMuteState
    }
    
    func toggleMute() {
        let newMuteState = !currentMuteState
        setMute(newMuteState)
    }
    
    func setMute(_ muted: Bool) {
        // Try to set mute state using Core Audio first
        if setCoreAudioMute(muted) {
            currentMuteState = muted
            
            // Also try to set via AVAudioApplication if available
            if #available(macOS 14.0, *), let audioApp = avAudioApplication {
                do {
                    try audioApp.setInputMuted(muted)
                    print("[AudioController] Successfully set mute via AVAudioApplication: \(muted)")
                } catch {
                    print("[AudioController] Failed to set mute via AVAudioApplication: \(error)")
                }
            }
            
            // Post notification for UI updates
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .audioStateChanged, object: nil)
            }
            
            print("[AudioController] Microphone mute set to: \(muted)")
        } else {
            print("[AudioController] Failed to set microphone mute state")
        }
    }
    
    private func setCoreAudioMute(_ muted: Bool) -> Bool {
        var muteValue: UInt32 = muted ? 1 : 0
        let dataSize = UInt32(MemoryLayout<UInt32>.size)
        
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &audioObjectPropertyAddress,
            0,
            nil,
            dataSize,
            &muteValue
        )
        
        if status != noErr {
            print("[AudioController] Core Audio set property failed with status: \(status)")
            return false
        }
        
        return true
    }
    
    private func refreshMuteState() {
        currentMuteState = getCoreAudioMuteState()
        
        // If AVAudioApplication is available, cross-check the state
        if #available(macOS 14.0, *), let audioApp = avAudioApplication {
            let avMuteState = audioApp.isInputMuted
            if currentMuteState != avMuteState {
                print("[AudioController] Mute state mismatch - Core Audio: \(currentMuteState), AVAudioApplication: \(avMuteState)")
                // Use AVAudioApplication state as authoritative on macOS 14+
                currentMuteState = avMuteState
            }
        }
        
        print("[AudioController] Current mute state: \(currentMuteState)")
    }
    
    private func getCoreAudioMuteState() -> Bool {
        var muteValue: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &audioObjectPropertyAddress,
            0,
            nil,
            &dataSize,
            &muteValue
        )
        
        if status != noErr {
            print("[AudioController] Core Audio get property failed with status: \(status)")
            return false
        }
        
        return muteValue != 0
    }
    
    func cleanup() {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        print("[AudioController] Cleanup completed")
    }
    
    // MARK: - Debug and Status Methods
    
    func getAudioDeviceInfo() -> String {
        var info = "Audio Device Information:\n"
        
        // Core Audio status
        info += "Core Audio Mute State: \(getCoreAudioMuteState())\n"
        
        // AVAudioApplication status (if available)
        if #available(macOS 14.0, *), let audioApp = avAudioApplication {
            info += "AVAudioApplication Mute State: \(audioApp.isInputMuted)\n"
            info += "AVAudioApplication Available: Yes\n"
        } else {
            info += "AVAudioApplication Available: No (macOS < 14.0)\n"
        }
        
        info += "Current Controller State: \(currentMuteState)"
        return info
    }
    
    func requestMicrophonePermission() {
        // Request microphone permission
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("[AudioController] Microphone permission granted")
                } else {
                    print("[AudioController] Microphone permission denied")
                }
            }
        }
    }
}

// MARK: - Extensions

extension AudioController {
    /// Check if the system supports advanced audio features
    var supportsAVAudioApplication: Bool {
        if #available(macOS 14.0, *) {
            return true
        }
        return false
    }
    
    /// Get a user-friendly status string
    var statusDescription: String {
        let baseStatus = currentMuteState ? "Muted" : "Active"
        let platformInfo = supportsAVAudioApplication ? " (AirPods gesture support)" : " (Core Audio only)"
        return baseStatus + platformInfo
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let audioStateChanged = Notification.Name("audioStateChanged")
}
