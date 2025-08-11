//
//  main.swift
//  AirPodsMicHelper
//
//  NSApplicationMain fallback entry point
//  Created on 11/08/2025.
//  Copyright © 2025 Rahnas. All rights reserved.
//

import Cocoa

// Main entry point for the application
// This serves as a fallback for NSApplicationMain when @main annotation
// is not available or when building with older Swift versions

// Note: The actual application logic is handled by AppDelegate.swift
// which uses the @main annotation as the primary entry point

#if !swift(>=5.3) || !canImport(SwiftUI)
// Fallback for older Swift versions that don't support @main
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
#endif
