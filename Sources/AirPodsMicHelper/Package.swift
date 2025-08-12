// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AirPodsMicHelper",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "AirPodsMicHelper",
            targets: ["AirPodsMicHelper"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/nhurden/MediaKeyTap.git", from: "2.2.0")
    ],
    targets: [
        .executableTarget(
            name: "AirPodsMicHelper",
            dependencies: ["MediaKeyTap"],
            path: "Sources/AirPodsMicHelper",
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox")
            ]
        ),
        .testTarget(
            name: "AirPodsMicHelperTests",
            dependencies: ["AirPodsMicHelper"]
        )
    ]
)
