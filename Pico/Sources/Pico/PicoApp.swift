import SwiftUI
import UserNotifications

@main
struct PicoApp: App {
    @StateObject private var medicationStore = MedicationStore()
    @StateObject private var notificationService = NotificationService.shared
    
    init() {
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(medicationStore)
                .environmentObject(notificationService)
                .onAppear {
                    // Request notification permissions when app starts
                    Task {
                        await notificationService.requestPermission()
                    }
                }
        }
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationService.shared.handleNotificationResponse(response)
        completionHandler()
    }
}
