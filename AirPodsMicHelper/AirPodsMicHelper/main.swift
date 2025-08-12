//
//  main.swift
//  AirPodsMicHelper
//
//  Main entry point for the menu bar application
//  Created on 11/08/2025.
//  Copyright © 2025 Rahnas. All rights reserved.
//

import Cocoa

// Set up the application delegate and run the main loop
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
