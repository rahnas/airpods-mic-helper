//
//  AppDelegate.swift
//  AirPodsMicHelper
//
//  Created on $(date)
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the status bar controller
        statusBarController = StatusBarController()
        
        // Prevent the app from appearing in the dock
        NSApp.setActivationPolicy(.accessory)
        
        // Keep the app running when all windows are closed
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up resources
        statusBarController?.cleanup()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        // Don't terminate when windows are closed (menu bar app)
        return false
    }
}
