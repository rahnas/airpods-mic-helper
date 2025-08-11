//
//  StatusBarController.swift
//  AirPodsMicHelper
//
//  Created on $(date)
//

import Cocoa

class StatusBarController {
    private var statusBarItem: NSStatusItem?
    private var menu: NSMenu?
    private var audioController: AudioController
    
    init() {
        self.audioController = AudioController()
        setupStatusBar()
        setupMenu()
        
        // Listen for audio state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioStateDidChange),
            name: .audioStateChanged,
            object: nil
        )
        
        // Update initial state
        updateMenuBarIcon()
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem?.button?.target = self
        statusBarItem?.button?.action = #selector(statusBarButtonClicked)
    }
    
    private func setupMenu() {
        menu = NSMenu()
        
        // Toggle mute item
        let toggleItem = NSMenuItem(title: "Toggle Microphone", action: #selector(toggleMicrophone), keyEquivalent: "m")
        toggleItem.target = self
        menu?.addItem(toggleItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Status item
        let statusItem = NSMenuItem(title: "Status: Unknown", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu?.addItem(statusItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit AirPods Mic Helper", action: #selector(quitApplication), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusBarItem?.menu = menu
    }
    
    @objc private func statusBarButtonClicked() {
        // For quick toggle - click the status bar icon to toggle mute
        toggleMicrophone()
    }
    
    @objc private func toggleMicrophone() {
        audioController.toggleMute()
    }
    
    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func audioStateDidChange() {
        DispatchQueue.main.async {
            self.updateMenuBarIcon()
            self.updateMenuStatus()
        }
    }
    
    private func updateMenuBarIcon() {
        guard let button = statusBarItem?.button else { return }
        
        let isMuted = audioController.isMuted
        let iconName = isMuted ? "mic.slash.fill" : "mic.fill"
        
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            image.isTemplate = true
            button.image = image
        }
        
        // Update tooltip
        button.toolTip = isMuted ? "Microphone is muted" : "Microphone is active"
    }
    
    private func updateMenuStatus() {
        guard let menu = menu else { return }
        
        // Find the status menu item (index 2)
        if menu.items.count > 2 {
            let statusItem = menu.items[2]
            let isMuted = audioController.isMuted
            statusItem.title = "Status: \(isMuted ? "Muted" : "Active")"
        }
        
        // Update toggle item text
        if let toggleItem = menu.items.first {
            let isMuted = audioController.isMuted
            toggleItem.title = isMuted ? "Unmute Microphone" : "Mute Microphone"
        }
    }
    
    func cleanup() {
        NotificationCenter.default.removeObserver(self)
        audioController.cleanup()
        
        if let statusBarItem = statusBarItem {
            NSStatusBar.system.removeStatusItem(statusBarItem)
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let audioStateChanged = Notification.Name("audioStateChanged")
}
