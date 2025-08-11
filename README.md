# AirPods Mic Helper

A Swift macOS menu bar application that provides global microphone mute/unmute functionality with seamless Chrome extension integration via Native Messaging.

## Architecture Overview

### Core Components

#### 1. Swift macOS Menu Bar App
- **Framework**: AppKit for menu bar integration
- **Audio Engine**: AVAudioEngine and Core Audio APIs
- **System Integration**: macOS AudioUnit framework for low-level audio control
- **UI**: Minimalist menu bar icon with status indicators

#### 2. Audio Control System
- **AVAudioApplication**: Primary interface for application-level audio management
- **Core Audio**: Direct hardware abstraction layer access
- **AudioUnit**: Real-time audio processing and routing
- **System Audio**: Global input device monitoring and control

#### 3. Chrome Extension Bridge
- **Native Messaging Host**: Bidirectional communication channel
- **JSON Protocol**: Structured message passing
- **Extension API**: Chrome extension manifest v3 compatibility
- **Security Layer**: Sandboxed communication with permission validation

### Data Flow

```
Chrome Extension → Native Messaging → macOS App → Core Audio → Hardware
                ←                  ←            ←             ←
```

1. **User Interaction**: Click in Chrome extension or menu bar
2. **Message Routing**: Native messaging protocol handles communication
3. **Audio Processing**: Swift app interfaces with Core Audio
4. **Hardware Control**: Direct microphone mute/unmute
5. **Status Sync**: Bidirectional state updates

## Features

- **Global Microphone Control**: Toggle mute/unmute from anywhere
- **Menu Bar Integration**: Native macOS status bar presence
- **Chrome Extension**: Browser-based control interface
- **Real-time Sync**: Instant status updates across all interfaces
- **System Audio Awareness**: Respects macOS audio routing
- **Low Resource Usage**: Minimal CPU and memory footprint

## Build Instructions

### Prerequisites

- **macOS**: 12.0 (Monterey) or later
- **Xcode**: 14.0 or later
- **Swift**: 5.7 or later
- **Chrome**: Version 90+ (for extension testing)

### Building the macOS App

1. **Clone the Repository**
   ```bash
   git clone https://github.com/rahnas/airpods-mic-helper.git
   cd airpods-mic-helper
   ```

2. **Open in Xcode**
   ```bash
   open AirPodsMicHelper.xcodeproj
   ```

3. **Configure Signing**
   - Select your development team in project settings
   - Ensure proper code signing certificates
   - Enable "Audio Input" capability

4. **Build and Run**
   ```bash
   # Command line build
   xcodebuild -project AirPodsMicHelper.xcodeproj -scheme AirPodsMicHelper -configuration Release
   
   # Or use Xcode GUI: Product → Build (⌘B)
   ```

### Installing the Chrome Extension

1. **Enable Developer Mode**
   - Open Chrome → Extensions → Developer mode

2. **Load Extension**
   ```bash
   # Navigate to chrome://extensions/
   # Click "Load unpacked"
   # Select the chrome-extension/ directory
   ```

3. **Configure Native Messaging**
   ```bash
   # Copy manifest to Chrome's native messaging directory
   cp native-messaging-manifest.json ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/
   ```

## Run Instructions

### First-Time Setup

1. **Grant Permissions**
   - **Microphone Access**: System Preferences → Security & Privacy → Microphone
   - **Accessibility**: Required for global hotkey support
   - **Background App Refresh**: Allow menu bar persistence

2. **Launch Application**
   ```bash
   # From Applications folder
   open /Applications/AirPodsMicHelper.app
   
   # Or from terminal
   ./build/Release/AirPodsMicHelper.app/Contents/MacOS/AirPodsMicHelper
   ```

3. **Verify Extension Connection**
   - Check menu bar icon appears
   - Test Chrome extension functionality
   - Confirm bidirectional communication

### Daily Usage

- **Menu Bar**: Click icon to toggle mute state
- **Chrome Extension**: Use browser toolbar button
- **Status Indicators**: Visual feedback in both interfaces
- **Hotkeys**: Configure global shortcuts (optional)

## Security Considerations

### Application Security

- **Sandboxing**: App runs in macOS sandbox environment
- **Minimal Permissions**: Only requests necessary audio access
- **Code Signing**: Properly signed for distribution security
- **Hardened Runtime**: Enhanced security protections enabled

### Native Messaging Security

- **Allowlisted Origins**: Chrome extension origin validation
- **Message Validation**: JSON schema enforcement
- **Process Isolation**: Separate processes for extension and native app
- **Secure Communication**: IPC through standard Chrome channels

### Audio System Security

- **Permission Gating**: Requires explicit user consent for microphone access
- **System Integration**: Uses official macOS AudioUnit APIs
- **No Audio Recording**: Only control, never captures audio data
- **Privacy Compliance**: Respects system-wide privacy settings

### Privacy Protection

- **No Data Collection**: Application doesn't store or transmit user data
- **Local Processing**: All operations performed locally
- **Transparent Operation**: Open source codebase for security audit
- **Minimal Network**: No external network connections required

## Troubleshooting

### Common Issues

1. **Microphone Access Denied**
   - Solution: Grant permissions in System Preferences

2. **Extension Not Connecting**
   - Check native messaging manifest installation
   - Verify app is running and accessible

3. **Menu Bar Icon Missing**
   - Restart application
   - Check accessibility permissions

4. **Audio Control Not Working**
   - Verify Core Audio permissions
   - Check for conflicting audio applications

### Debug Mode

```bash
# Enable verbose logging
AIRPODS_MIC_DEBUG=1 ./AirPodsMicHelper.app/Contents/MacOS/AirPodsMicHelper

# Check native messaging logs
tail -f ~/Library/Logs/Chrome/native_messaging.log
```

## Development

### Code Structure

```
AirPodsMicHelper/
├── Sources/
│   ├── MenuBar/          # Menu bar UI components
│   ├── AudioEngine/      # Core Audio integration
│   ├── NativeMessaging/  # Chrome extension bridge
│   └── Utilities/        # Helper functions
├── chrome-extension/     # Chrome extension source
├── Resources/           # App resources and assets
└── Tests/              # Unit and integration tests
```

### Contributing

1. Fork the repository
2. Create feature branch
3. Implement changes with tests
4. Submit pull request

## License

MIT License - see LICENSE file for details.

## Compatibility

- **macOS**: 12.0+ (Monterey, Ventura, Sonoma)
- **Chrome**: 90+ (Manifest V3 compatible)
- **Architecture**: Intel and Apple Silicon (Universal Binary)
- **Audio**: Compatible with all macOS audio devices
