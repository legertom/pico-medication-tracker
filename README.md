# Pico - Injection-Based Medication Tracker

Pico is a simple and elegant iOS application designed to help users track injection-based medications. Whether you're managing insulin, hormone therapy, or other injectable medications, Pico provides an intuitive interface to log injections, track schedules, and maintain a comprehensive history.

## Features

- **Medication Management**: Add and manage multiple injection-based medications
- **Injection Tracking**: Record injections with customizable injection sites and notes
- **Schedule Monitoring**: Track injection frequency and get overdue notifications
- **History Management**: View comprehensive injection history with timestamps
- **Multiple Injection Sites**: Support for subcutaneous, intramuscular, intravenous, and intradermal injections
- **Flexible Scheduling**: Daily, twice daily, weekly, bi-weekly, monthly, and as-needed frequencies

## Screenshots

*Screenshots will be added as the app is developed*

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later for development
- Swift 5.0

## Installation

### For Development

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd pico-medication-tracker
   ```

2. Open the Xcode project:
   ```bash
   open Pico.xcodeproj
   ```

3. Build and run the project in Xcode

### For Users

*App Store distribution instructions will be added when available*

## Project Structure

```
Pico/
├── Sources/
│   ├── Pico/           # App entry point
│   ├── Models/         # Data models
│   ├── Views/          # SwiftUI views
│   └── Services/       # Business logic and data management
├── Resources/          # Assets, images, and other resources
└── Tests/             # Unit and UI tests
```

## Usage

### Adding a Medication

1. Tap the "+" button in the Medications tab
2. Enter the medication name and dosage
3. Select the injection site type (subcutaneous, intramuscular, etc.)
4. Choose the injection frequency
5. Add any relevant notes
6. Tap "Save"

### Recording an Injection

1. From the medication list, tap "Record Injection" on the desired medication
2. Confirm or change the injection site
3. Add any notes about the injection
4. Tap "Record"

### Viewing History

Switch to the History tab to view all injection records chronologically, with the ability to delete records if needed.

## Data Storage

Pico uses UserDefaults for local data storage. All data remains on your device and is not shared with external services.

## Privacy

- No personal data is transmitted to external servers
- All medication and injection data is stored locally on your device
- No analytics or tracking is implemented

## Contributing

This is a personal project, but contributions are welcome! Please feel free to:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## Support

If you encounter any issues or have feature requests, please:

- Check the existing issues on GitHub
- Create a new issue with detailed information
- Contact support at support@pico.app

## License

*License information will be added*

## Disclaimer

**Important**: This app is for informational and tracking purposes only. It is not intended to replace professional medical advice, diagnosis, or treatment. Always consult with qualified healthcare professionals regarding your medication regimen. The developers are not responsible for any medical decisions made based on information tracked in this app.

## Version History

### v1.0.0 (Current)
- Initial release
- Basic medication tracking
- Injection recording
- History management
- Support for multiple injection sites and frequencies

---

*Built with ❤️ using SwiftUI*