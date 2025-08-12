//
//  StatusBarController.swift
//  AirPods Mic Helper
//
//  Created by GitHub Copilot on 2025-08-11.
//  Copyright © 2025 Rahnas. All rights reserved.
//

import Cocoa
import AppKit
import AVFoundation

class StatusBarController: NSObject {
    
    // MARK: - Properties
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem?
    private var menu: NSMenu
    private var audioController: AudioController
    private var statusWindow: StatusWindow?
    
    // Icons for different states
    private let micActiveIcon = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Microphone Active")
    private let micMutedIcon = NSImage(systemSymbolName: "mic.slash.fill", accessibilityDescription: "Microphone Muted")
    
    // MARK: - Initialization
    init(audioController: AudioController) {
        statusBar = NSStatusBar.system
        menu = NSMenu()
        self.audioController = audioController
        
        super.init()
        
        // Configure menu
        setupMenu()
        
        // Listen for audio state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioStateChanged),
            name: .audioStateChanged,
            object: nil
        )
    }
    
    // MARK: - Status Item Setup
    func setupStatusItem() {
        // Create status item with fixed length
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let statusItem = statusItem else {
            print("Failed to create status item")
            return
        }
        
        // Configure button properties
        if let button = statusItem.button {
            button.image = micActiveIcon
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
            button.toolTip = "AirPods Mic Helper - Click to toggle mute"
            button.target = self
            button.action = #selector(statusItemClicked)
        }
        
        // Set menu
        statusItem.menu = menu
        
        // Initial state setup
        updateStatusIcon()
    }
    
    // MARK: - Menu Setup
    private func setupMenu() {
        menu.removeAllItems()
        
        // Toggle mute item
        let toggleItem = NSMenuItem(title: "Toggle Mute", action: #selector(toggleMute), keyEquivalent: "m")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Status item
        let statusMenuItem = NSMenuItem(title: getMicStatusText(), action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Show status window item
        let showStatusItem = NSMenuItem(title: "Show Status Window", action: #selector(showStatusWindow), keyEquivalent: "s")
        showStatusItem.target = self
        menu.addItem(showStatusItem)
        
        // About item
        let aboutItem = NSMenuItem(title: "About AirPods Mic Helper", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Audio State Handling
    @objc private func audioStateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusIcon()
        }
    }
    
    // MARK: - Status Icon Update
    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        
        let isMuted = audioController.isMuted
        if isMuted {
            button.image = micMutedIcon
            button.toolTip = "AirPods Mic Helper - Microphone Muted (Click to unmute)"
        } else {
            button.image = micActiveIcon
            button.toolTip = "AirPods Mic Helper - Microphone Active (Click to mute)"
        }
        
        button.image?.size = NSSize(width: 18, height: 18)
        button.image?.isTemplate = true
        
        // Update menu status
        updateMenuStatus()
    }
    
    private func updateMenuStatus() {
        // Find and update the status menu item
        for item in menu.items {
            if !item.isEnabled && item.title.contains("Microphone") {
                item.title = getMicStatusText()
                break
            }
        }
    }
    
    private func getMicStatusText() -> String {
        let isMuted = audioController.isMuted
        return isMuted ? "🔇 Microphone: Muted" : "🎤 Microphone: Active"
    }
    
    // MARK: - Actions
    @objc private func statusItemClicked() {
        toggleMute()
    }
    
    @objc private func toggleMute() {
        audioController.toggleMute()
    }
    
    @objc private func showStatusWindow() {
        if statusWindow == nil {
            statusWindow = StatusWindow(audioController: audioController)
        }
        statusWindow?.showWindow()
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "AirPods Mic Helper"
        alert.informativeText = "A macOS menu bar application for global microphone mute/unmute control.\n\nVersion 1.0\n© 2025 Rahnas"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(self)
    }
    
    // MARK: - Cleanup
    func cleanup() {
        if let statusItem = statusItem {
            statusBar.removeStatusItem(statusItem)
        }
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - Public Interface
extension StatusBarController {
    
    /// Get current mute state
    var isMicrophoneMuted: Bool {
        return audioController.isMuted
    }
    
    /// Set mute state programmatically (for external control)
    func setMuteState(_ muted: Bool) {
        audioController.setMute(muted)
    }
    
    /// Toggle mute state programmatically
    func toggleMuteState() {
        audioController.toggleMute()
    }
}
