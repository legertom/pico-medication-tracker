# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Pico is an iOS medication tracking application built with SwiftUI that helps users track injection-based medications. The app allows users to manage multiple medications, record injections with customizable sites and notes, track schedules, and maintain comprehensive history.

## Development Commands

### Building and Running
```bash
# Open the Xcode project
open Pico.xcodeproj

# Build the project (from Xcode or command line)
xcodebuild -project Pico.xcodeproj -scheme Pico -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project Pico.xcodeproj clean
```

### Development Workflow
```bash
# Check Swift version compatibility
swift --version

# Find all Swift source files
find Pico -name "*.swift"

# Run Swift formatter (if installed)
swift-format --in-place --recursive Pico/Sources/
```

## Architecture

### High-Level Structure
The app follows a clean SwiftUI architecture with clear separation of concerns:

- **Models**: Core data structures (`Medication`, `InjectionRecord`, enums for injection sites and frequencies)
- **Services**: Business logic and data persistence (`MedicationStore` using `ObservableObject` and UserDefaults)
- **Views**: SwiftUI interface components organized in a single-file approach but could be split as the app grows
- **App Entry Point**: `PicoApp` with environment object injection

### Data Flow Architecture
- **State Management**: `MedicationStore` serves as the single source of truth using `@Published` properties
- **Data Persistence**: UserDefaults with JSON encoding/decoding for local storage
- **View Updates**: SwiftUI's reactive approach with `@EnvironmentObject` for global state
- **Navigation**: Tab-based with sheet presentations for modal workflows

### Key Components
- **MedicationStore**: Central data management with CRUD operations for medications and injection records
- **Medication Model**: Core entity with support for different injection sites, frequencies, and tracking
- **InjectionRecord**: Historical tracking with timestamps and detailed information
- **ContentView**: Tab coordinator managing three main sections (Medications, History, Settings)

## Code Organization

### File Structure
```
Pico/Sources/
├── Pico/          # App entry point and configuration
├── Models/        # Data models and business entities
├── Views/         # SwiftUI views (currently in single file, consider splitting)
└── Services/      # Business logic and data management
```

### Key Design Patterns
- **MVVM**: Models with ObservableObject view models and SwiftUI views
- **Environment Objects**: Global state injection for cross-view data sharing
- **Repository Pattern**: `MedicationStore` abstracts data persistence logic
- **Protocol-Oriented**: Enums with display properties for consistent UI representation

## Development Guidelines

### Adding New Features
1. **Models**: Add new data structures in `Models/` directory
2. **Services**: Extend `MedicationStore` or create new service classes
3. **Views**: Consider splitting large view files as features grow
4. **Persistence**: Extend UserDefaults keys and encoding/decoding as needed

### UI Consistency
- Use `InjectionSite` and `MedicationFrequency` enums for consistent data representation
- Follow the tab-based navigation pattern
- Maintain the blue accent color scheme (`Color.blue`)
- Use sheet presentations for modal workflows (Add/Edit medication, Record injection)

### Data Management
- All data operations should go through `MedicationStore`
- Use `@Published` properties for reactive UI updates
- Maintain referential integrity between medications and injection records
- Handle UserDefaults encoding/decoding errors gracefully

### Testing Considerations
- No test files currently exist - consider adding unit tests for `MedicationStore`
- SwiftUI Preview providers are included for development
- Test data persistence and CRUD operations independently

## Technical Details

### Requirements
- iOS 17.0+ (set in project configuration)
- Swift 5.0+
- Xcode 15.0+ for development
- SwiftUI framework

### Dependencies
- No external dependencies - uses native iOS frameworks only
- Foundation for data models and persistence
- SwiftUI for user interface
- Combine for reactive programming patterns

### Data Storage
- Local storage only using UserDefaults
- JSON encoding/decoding for complex objects
- No network requests or external data sync
- All data remains on device for privacy

This architecture supports the app's current scope while providing clear extension points for future features like notifications, data export, or cloud sync.