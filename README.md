# System Metrics Widget for macOS

A SwiftUI widget that provides real-time monitoring of key system metrics on your Mac desktop.

## System Metrics Widget

The System Metrics Widget provides at-a-glance information about your Mac's:

- **Disk Space**: View total, free, and used disk space on your main volume
- **CPU Temperature**: Monitor your Mac's CPU temperature
- **RAM Usage**: Track memory usage and availability 
- **Network Traffic**: Monitor data transfer on your active network interfaces (Wi-Fi, Ethernet, Bluetooth)

### Widget Sizes

Each widget is available in three sizes:

- **Small**: Compact view showing usage percentages and CPU temperature
- **Medium**: More detailed view with free space information and network traffic stats
- **Large**: Comprehensive view with all metrics and progress bars

### Screenshots

(Screenshots will be added once the app is built and running)

## Features

- **Real-time Updates**: Metrics automatically refresh at regular intervals
- **Customizable Views**: Choose from small, medium, or large widget sizes
- **At-a-glance Status**: Color-coded indicators for quick status checks
- **Non-intrusive**: Lightweight design that sits on your desktop

## Installation

1. Clone this repository or download the source code
2. Open the project in Xcode
3. Build and run the application
4. Add the widget to your desktop:
   - Long press on your desktop
   - Click "Edit Widgets"
   - Find the "System Metrics" widget
   - Drag it to your desktop

## Technical Implementation

The widget uses a number of system APIs to collect metrics:

- **Disk Space**: Uses `URLResourceKey` to query volume information
- **Memory Usage**: Uses the `host_statistics64` API to get memory statistics
- **CPU Temperature**: Currently uses simulated data (a proper implementation would use SMC access)
- **Network Traffic**: Currently uses simulated data (a proper implementation would use `getifaddrs` or similar APIs)

### Notes on System Access

Some system metrics, like CPU temperature, require special permissions or specialized libraries to access. In a production environment, you might want to:

1. Integrate a library like [SMCKit](https://github.com/beltex/SMCKit) for SMC access (CPU temperature)
2. Implement proper network statistics gathering using low-level networking APIs

## Privacy & Security

This widget runs entirely on your local Mac and does not transmit any data over the network. No personal information or system metrics are shared with external services.

## Requirements

- macOS 12 (Monterey) or later
- Xcode 13 or later for development

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Apple for the WidgetKit framework
- The open-source community for documentation on accessing system metrics 