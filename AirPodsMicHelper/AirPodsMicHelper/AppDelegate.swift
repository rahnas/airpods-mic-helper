//
//  AppDelegate.swift
//  AirPods Mic Helper
//
//  Created by GitHub Copilot on 2025-08-11.
//  Copyright © 2025 Rahnas. All rights reserved.
//

import Cocoa
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController?
    private var audioController: AudioController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar-only app
        NSApp.setActivationPolicy(.accessory)
        
        // Request accessibility permissions for AirPods button detection
        requestAccessibilityPermissions()
        
        // Initialize audio controller
        audioController = AudioController()
        
        // Request microphone permission
        audioController?.requestMicrophonePermission()
        
        // Initialize status bar controller and connect it to audio controller
        statusBarController = StatusBarController(audioController: audioController!)
        statusBarController?.setupStatusItem()
        
        // Make app eligible for remote control events
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources
        audioController?.cleanup()
        statusBarController?.cleanup()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in menu bar even when no windows are open
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    private func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessibilityEnabled {
            print("[AppDelegate] ⚠️ Accessibility access required for AirPods button detection")
            
            let alert = NSAlert()
            alert.messageText = "Accessibility Access Required"
            alert.informativeText = "This app needs accessibility access to detect AirPods button presses. Please enable it in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Open System Preferences")
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                // Open System Preferences
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
        } else {
            print("[AppDelegate] ✅ Accessibility permissions granted")
        }
    }
}

// MARK: - Menu Actions
extension AppDelegate {
    
    @objc func quitApplication(_ sender: Any?) {
        NSApp.terminate(self)
    }
    
    @objc func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(self)
    }
}
