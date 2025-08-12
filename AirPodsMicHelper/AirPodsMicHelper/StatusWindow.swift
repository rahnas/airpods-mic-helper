//
//  StatusWindow.swift
//  AirPods Mic Helper
//
//  Created on 2025-08-12.
//  Copyright © 2025 Rahnas. All rights reserved.
//

import Cocoa
import AppKit

class StatusWindow: NSWindowController {
    
    // MARK: - Properties
    private var audioController: AudioController
    private var statusLabel: NSTextField!
    private var iconImageView: NSImageView!
    private var detailsLabel: NSTextField!
    
    // Icons for different states
    private let micActiveIcon = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Microphone Active")
    private let micMutedIcon = NSImage(systemSymbolName: "mic.slash.fill", accessibilityDescription: "Microphone Muted")
    
    // MARK: - Initialization
    init(audioController: AudioController) {
        self.audioController = audioController
        
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
        setupViews()
        setupConstraints()
        updateStatus()
        
        // Listen for audio state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioStateChanged),
            name: .audioStateChanged,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Window Setup
    private func setupWindow() {
        guard let window = window else { return }
        
        window.title = "AirPods Mic Helper - Status"
        window.center()
        window.setFrameAutosaveName("StatusWindow")
        window.isReleasedWhenClosed = false
        
        // Make window appear above other windows but not always on top
        window.level = .floating
        
        // Set minimum size
        window.minSize = NSSize(width: 280, height: 180)
    }
    
    // MARK: - View Setup
    private func setupViews() {
        guard let window = window else { return }
        
        // Create content view
        let contentView = NSView()
        window.contentView = contentView
        
        // Create icon image view
        iconImageView = NSImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addSubview(iconImageView)
        
        // Create status label
        statusLabel = NSTextField(labelWithString: "Microphone Status")
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        statusLabel.alignment = .center
        contentView.addSubview(statusLabel)
        
        // Create details label
        detailsLabel = NSTextField(labelWithString: "Loading...")
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.font = NSFont.systemFont(ofSize: 14)
        detailsLabel.alignment = .center
        detailsLabel.textColor = .secondaryLabelColor
        contentView.addSubview(detailsLabel)
        
        // Create toggle button
        let toggleButton = NSButton(title: "Toggle Mute", target: self, action: #selector(toggleMute))
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.bezelStyle = .rounded
        toggleButton.controlSize = .large
        contentView.addSubview(toggleButton)
        
        // Create refresh button
        let refreshButton = NSButton(title: "Refresh Status", target: self, action: #selector(refreshStatus))
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.bezelStyle = .rounded
        refreshButton.controlSize = .regular
        contentView.addSubview(refreshButton)
        
        // Store button references for later use
        self.toggleButton = toggleButton
        self.refreshButton = refreshButton
    }
    
    private var toggleButton: NSButton!
    private var refreshButton: NSButton!
    
    // MARK: - Constraints Setup
    private func setupConstraints() {
        guard let contentView = window?.contentView else { return }
        
        NSLayoutConstraint.activate([
            // Icon constraints
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),
            
            // Status label constraints
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 15),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            
            // Details label constraints
            detailsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            detailsLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5),
            detailsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            detailsLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            
            // Toggle button constraints
            toggleButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            toggleButton.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 25),
            toggleButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            // Refresh button constraints
            refreshButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            refreshButton.topAnchor.constraint(equalTo: toggleButton.bottomAnchor, constant: 10),
            refreshButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            refreshButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }
    
    // MARK: - Status Updates
    @objc private func audioStateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatus()
        }
    }
    
    private func updateStatus() {
        let isMuted = audioController.isMuted
        let statusDescription = audioController.statusDescription
        
        // Update icon
        if isMuted {
            iconImageView.image = micMutedIcon
            iconImageView.contentTintColor = .systemRed
        } else {
            iconImageView.image = micActiveIcon
            iconImageView.contentTintColor = .systemGreen
        }
        
        // Update status text
        statusLabel.stringValue = isMuted ? "Microphone Muted" : "Microphone Active"
        statusLabel.textColor = isMuted ? .systemRed : .systemGreen
        
        // Update details
        detailsLabel.stringValue = statusDescription
        
        // Update button text
        toggleButton.title = isMuted ? "Unmute Microphone" : "Mute Microphone"
    }
    
    // MARK: - Actions
    @objc private func toggleMute() {
        audioController.toggleMute()
    }
    
    @objc private func refreshStatus() {
        updateStatus()
        
        // Also show current audio device info in console
        print("Audio Device Info:")
        print(audioController.getAudioDeviceInfo())
    }
}

// MARK: - Public Interface
extension StatusWindow {
    
    /// Show the status window
    func showWindow() {
        showWindow(nil)
        updateStatus()
    }
    
    /// Get current mute state
    var isMicrophoneMuted: Bool {
        return audioController.isMuted
    }
}
