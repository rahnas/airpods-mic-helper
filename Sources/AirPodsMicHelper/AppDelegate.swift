//
//  AppDelegate.swift
//  AirPodsMicHelper
//
//  Created on 11/08/2025.
//  Copyright © 2025 Rahnas. All rights reserved.
//

import Cocoa
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    private var statusBarItem: NSStatusItem!
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupApplication()
        setupMenuBar()
        
        NSLog("AirPods Mic Helper started successfully")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        cleanup()
    }
    
    // MARK: - Setup Methods
    
    private func setupApplication() {
        // Configure app to run without dock icon (menu bar only)
        NSApp.setActivationPolicy(.accessory)
        
        // Request microphone permission
        requestMicrophonePermission()
    }
    
    private func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            // Set initial icon (microphone unmuted)
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Microphone")
            button.toolTip = "AirPods Mic Helper - Click to toggle mute"
            button.target = self
            button.action = #selector(statusBarButtonClicked)
        }
    }
    
    // MARK: - Permission Handling
    
    private func requestMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            NSLog("Microphone permission already granted")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        NSLog("Microphone permission granted")
                    } else {
                        NSLog("Microphone permission denied")
                        self.showPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert()
        @unknown default:
            NSLog("Unknown microphone permission status")
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Microphone Access Required"
        alert.informativeText = "AirPods Mic Helper needs microphone access to control mute/unmute."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Actions
    
    @objc private func statusBarButtonClicked() {
        // TODO: Implement mute toggle functionality
        NSLog("Menu bar icon clicked")
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        NSLog("AirPods Mic Helper stopped")
    }
}
