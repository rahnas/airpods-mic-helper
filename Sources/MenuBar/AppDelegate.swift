//
//  AppDelegate.swift
//  AirPods Mic Helper
//
//  Created by GitHub Copilot on 2025-08-11.
//  Copyright © 2025 Rahnas. All rights reserved.
//

import Cocoa
import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar-only app
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize status bar controller
        statusBarController = StatusBarController()
        statusBarController?.setupStatusItem()
        
        // Prevent app from terminating when last window is closed
        NSApp.servicesMenuSendTypes = []
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources
        statusBarController?.cleanup()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in menu bar even when no windows are open
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
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
