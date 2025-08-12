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
    private var currentInputDeviceID: AudioDeviceID = kAudioObjectUnknown
    private var airPodsDeviceID: AudioDeviceID = kAudioObjectUnknown
    private var pollingTimer: Timer?
    private var pollingLogCounter: Int = 0
    
    // Media Key Detection for AirPods
    private var mediaKeyController: MediaKeyController?
    
    init() {
        // Initialize Core Audio property address for global input mute
        audioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessInputMute,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        setupAudioApplication()
        setupDeviceMonitoring()
        findAirPodsDevice()
        refreshMuteState()
        startPollingForAirPodsButton()
        setupMediaKeyDetection()
    }
    
    private func setupAudioApplication() {
        print("[AudioController] 🔧 Setting up AVAudioApplication...")
        
        if #available(macOS 14.0, *) {
            // For macOS Sonoma (14+), use AVAudioApplication for AirPods gesture support
            avAudioApplication = AVAudioApplication.shared
            
            if let audioApp = avAudioApplication {
                print("[AudioController] 📱 AVAudioApplication.shared obtained")
                print("[AudioController] 🎯 Current AVAudioApplication mute state: \(audioApp.isInputMuted)")
                
                // Set up the input mute state change handler (this is the key for AirPods button detection)
                do {
                    try audioApp.setInputMuteStateChangeHandler { [weak self] isMuted in
                        print("[AudioController] 🎧 AirPods button pressed! New mute state: \(isMuted)")
                        print("[AudioController] 🎧 Handler called at: \(Date())")
                        
                        DispatchQueue.main.async {
                            self?.handleAirPodsButtonPress(isMuted: isMuted)
                        }
                        
                        // Return true to indicate we handled the change
                        return true
                    }
                    print("[AudioController] ✅ AVAudioApplication mute state change handler set successfully")
                } catch {
                    print("[AudioController] ❌ Failed to set AVAudioApplication mute state change handler: \(error)")
                }
                
                // Also try to set up notification-based listening as backup
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleAVAudioApplicationNotification),
                    name: AVAudioApplication.inputMuteStateChangeNotification,
                    object: nil
                )
                print("[AudioController] 📢 Added notification observer for AVAudioApplication changes")
            } else {
                print("[AudioController] ❌ Failed to get AVAudioApplication.shared")
            }
            
            print("[AudioController] AVAudioApplication setup completed for macOS Sonoma+")
        } else {
            print("[AudioController] Running on macOS < 14.0, using Core Audio only")
        }
    }
    
    // MARK: - AirPods Button Press Handling
    
    private func handleAirPodsButtonPress(isMuted: Bool) {
        print("[AudioController] Handling AirPods button press - New state: \(isMuted ? "Muted" : "Unmuted")")
        
        // Update our internal state to match the AirPods gesture
        currentMuteState = isMuted
        
        // For now, just update the UI - don't try to actually mute the microphone
        // We'll add actual muting functionality later
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .audioStateChanged, object: nil)
        
        print("[AudioController] ✅ AirPods button press handled - App UI updated")
    }
    
    @objc private func handleAVAudioApplicationNotification(_ notification: Notification) {
        print("[AudioController] 📢 AVAudioApplication notification received: \(notification.name)")
        print("[AudioController] 📢 Notification userInfo: \(notification.userInfo ?? [:])")
        
        if #available(macOS 14.0, *), let audioApp = avAudioApplication {
            let currentMuteState = audioApp.isInputMuted
            print("[AudioController] 📢 Notification - Current mute state: \(currentMuteState)")
            
            DispatchQueue.main.async {
                self.handleAirPodsButtonPress(isMuted: currentMuteState)
            }
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
        print("[AudioController] 🎯 App UI toggle requested - New state: \(muted ? "Muted" : "Unmuted")")
        
        // For now, just update the UI state without actually muting the microphone
        // This allows us to focus on testing AirPods button detection
        currentMuteState = muted
        
        // Post notification for UI updates
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .audioStateChanged, object: nil)
        }
        
        print("[AudioController] ✅ App UI state updated (actual muting disabled for testing)")
        
        // TODO: Later we'll re-enable actual microphone muting here:
        // - setCoreAudioMute(muted)
        // - audioApp.setInputMuted(muted)
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
    
    // MARK: - Device Detection and Monitoring
    
    private func setupDeviceMonitoring() {
        // Set up property listener for default input device changes
        var devicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &devicePropertyAddress,
            { (objectID, numAddresses, addresses, clientData) -> OSStatus in
                guard let clientData = clientData else { return noErr }
                let audioController = Unmanaged<AudioController>.fromOpaque(clientData).takeUnretainedValue()
                audioController.handleDeviceChange()
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        if status != noErr {
            print("[AudioController] Failed to add device change listener: \(status)")
        } else {
            print("[AudioController] Device monitoring setup completed")
        }
    }
    
    @objc private func handleDeviceChange() {
        print("[AudioController] Audio device changed")
        findAirPodsDevice()
        refreshMuteState()
        
        // Post notification for UI updates
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .audioStateChanged, object: nil)
        }
    }
    
    private func findAirPodsDevice() {
        // Get current input device
        currentInputDeviceID = getCurrentInputDevice()
        
        // Check if current device is AirPods
        if isAirPodsDevice(currentInputDeviceID) {
            airPodsDeviceID = currentInputDeviceID
            print("[AudioController] Found AirPods as current input device: \(airPodsDeviceID)")
        } else {
            // Search for AirPods in all devices
            airPodsDeviceID = findAirPodsInAllDevices()
            if airPodsDeviceID != kAudioObjectUnknown {
                print("[AudioController] Found AirPods device: \(airPodsDeviceID)")
            } else {
                print("[AudioController] No AirPods device found")
            }
        }
    }
    
    private func getCurrentInputDevice() -> AudioDeviceID {
        var deviceID: AudioDeviceID = kAudioObjectUnknown
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceID
        )
        
        if status != noErr {
            print("[AudioController] Failed to get current input device: \(status)")
        }
        
        return deviceID
    }
    
    private func isAirPodsDevice(_ deviceID: AudioDeviceID) -> Bool {
        guard deviceID != kAudioObjectUnknown else { return false }
        
        let deviceName = getDeviceName(deviceID)
        let manufacturerName = getDeviceManufacturer(deviceID)
        
        print("[AudioController] Checking device - Name: '\(deviceName)', Manufacturer: '\(manufacturerName)'")
        
        // Check for AirPods patterns in device name
        let airPodsPatterns = ["AirPods", "airpods", "AIRPODS"]
        let applePatterns = ["Apple", "apple", "APPLE"]
        
        let isAirPodsName = airPodsPatterns.contains { deviceName.contains($0) }
        let isAppleDevice = applePatterns.contains { manufacturerName.contains($0) }
        
        return isAirPodsName || (isAppleDevice && deviceName.lowercased().contains("headphone"))
    }
    
    private func findAirPodsInAllDevices() -> AudioDeviceID {
        var deviceCount: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get device count
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else {
            print("[AudioController] Failed to get device count: \(status)")
            return kAudioObjectUnknown
        }
        
        deviceCount = dataSize / UInt32(MemoryLayout<AudioDeviceID>.size)
        print("[AudioController] Found \(deviceCount) audio devices")
        
        // Get all devices
        var devices = Array<AudioDeviceID>(repeating: kAudioObjectUnknown, count: Int(deviceCount))
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &devices
        )
        
        guard status == noErr else {
            print("[AudioController] Failed to get device list: \(status)")
            return kAudioObjectUnknown
        }
        
        // Search for AirPods device
        for device in devices {
            if hasInputStreams(device) && isAirPodsDevice(device) {
                return device
            }
        }
        
        return kAudioObjectUnknown
    }
    
    private func hasInputStreams(_ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        return status == noErr && dataSize > 0
    }
    
    private func getDeviceName(_ deviceID: AudioDeviceID) -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        var deviceName: CFString = "" as CFString
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceName
        )
        
        if status == noErr {
            return deviceName as String
        }
        
        return "Unknown Device"
    }
    
    private func getDeviceManufacturer(_ deviceID: AudioDeviceID) -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceManufacturerCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        var manufacturer: CFString = "" as CFString
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &manufacturer
        )
        
        if status == noErr {
            return manufacturer as String
        }
        
        return "Unknown Manufacturer"
    }
    
    // MARK: - Polling for AirPods Button Detection
    
    private func startPollingForAirPodsButton() {
        guard #available(macOS 14.0, *) else {
            print("[AudioController] Polling not available on macOS < 14.0")
            return
        }
        
        print("[AudioController] 🔄 Starting polling for AirPods button changes")
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.pollAVAudioApplicationState()
        }
    }
    
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        print("[AudioController] ⏹️ Stopped polling for AirPods button changes")
    }
    
    @objc private func pollAVAudioApplicationState() {
        guard #available(macOS 14.0, *), let audioApp = avAudioApplication else { return }
        
        let newMuteState = audioApp.isInputMuted
        
        // Add periodic status logging (every 5 seconds)
        pollingLogCounter += 1
        if pollingLogCounter % 50 == 0 { // Every 5 seconds (50 * 0.1s)
            print("[AudioController] 📊 Polling status - AVAudioApp mute: \(newMuteState), App state: \(currentMuteState)")
        }
        
        // Only act if the state has changed
        if newMuteState != currentMuteState {
            print("[AudioController] 🔄 Polling detected state change: \(currentMuteState) -> \(newMuteState)")
            print("[AudioController] 🔄 Change detected at: \(Date())")
            
            DispatchQueue.main.async { [weak self] in
                self?.handleAirPodsButtonPress(isMuted: newMuteState)
            }
        }
    }
    
    // MARK: - Media Key Detection for AirPods
    
    private func setupMediaKeyDetection() {
        print("[AudioController] 🎵 Setting up MediaKey detection for AirPods button...")
        
        mediaKeyController = MediaKeyController()
        mediaKeyController?.delegate = self
        
        print("[AudioController] ✅ MediaKey detection setup completed")
    }
    
    func cleanup() {
        // Stop media key detection
        mediaKeyController?.stop()
        mediaKeyController = nil
        
        // Stop polling
        stopPolling()
        
        // Remove property listeners
        var devicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectRemovePropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &devicePropertyAddress,
            { (objectID, numAddresses, addresses, clientData) -> OSStatus in
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        print("[AudioController] Cleanup completed")
    }
    
    // MARK: - Debug and Status Methods
    
    func getAudioDeviceInfo() -> String {
        var info = "Audio Device Information:\n"
        
        // Current input device
        let currentDevice = getCurrentInputDevice()
        info += "Current Input Device: \(getDeviceName(currentDevice)) (ID: \(currentDevice))\n"
        info += "Current Device Manufacturer: \(getDeviceManufacturer(currentDevice))\n"
        
        // AirPods detection
        if airPodsDeviceID != kAudioObjectUnknown {
            info += "AirPods Device Found: \(getDeviceName(airPodsDeviceID)) (ID: \(airPodsDeviceID))\n"
            info += "AirPods is Current Device: \(airPodsDeviceID == currentDevice ? "Yes" : "No")\n"
        } else {
            info += "AirPods Device: Not Found\n"
        }
        
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

// MARK: - MediaKeyControllerDelegate

extension AudioController: MediaKeyControllerDelegate {
    func mediaKeyController(_ controller: MediaKeyController, didDetectAirPodsButtonPress action: MediaKeyController.AirPodsAction) {
        NSLog("[AudioController] 🎵 MediaKey detected AirPods button press - Action: \(action)")
        print("[AudioController] 🎵 MediaKey detected AirPods button press - Action: \(action)")
        
        switch action {
        case .toggleMute:
            // Toggle the current mute state
            let newMuteState = !currentMuteState
            NSLog("[AudioController] 🎵 MediaKey triggering mute toggle: \(currentMuteState) -> \(newMuteState)")
            print("[AudioController] 🎵 MediaKey triggering mute toggle: \(currentMuteState) -> \(newMuteState)")
            
            // Update internal state and notify UI
            currentMuteState = newMuteState
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: .audioStateChanged, object: nil)
            
            NSLog("[AudioController] ✅ MediaKey AirPods button press handled - New state: \(newMuteState ? "Muted" : "Unmuted")")
            print("[AudioController] ✅ MediaKey AirPods button press handled - New state: \(newMuteState ? "Muted" : "Unmuted")")
        
        case .nextTrack:
            print("[AudioController] 🎵 MediaKey next track pressed (not implemented for mic app)")
        
        case .previousTrack:
            print("[AudioController] 🎵 MediaKey previous track pressed (not implemented for mic app)")
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
