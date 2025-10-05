import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            checkAuthorizationStatus()
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleNotification(for medication: Medication) {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        // Remove existing notifications for this medication
        cancelNotifications(for: medication)
        
        // Don't schedule for "as needed" medications
        guard let intervalDays = medication.frequency.intervalInDays else {
            return
        }
        
        // Calculate next due date
        let nextDueDate: Date
        if let lastInjection = medication.lastInjectionDate {
            nextDueDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: lastInjection) ?? Date()
        } else {
            // If no injections yet, schedule for tomorrow
            nextDueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
        
        // Only schedule if the date is in the future
        guard nextDueDate > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "💉 Injection Reminder"
        content.body = "Time for your \(medication.name) injection (\(medication.dosage))"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "medicationName": medication.name
        ]
        
        // Create trigger for the specific date and time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "medication-\(medication.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Scheduled notification for \(medication.name) at \(nextDueDate)")
            }
        }
    }
    
    func scheduleRecurringNotifications(for medication: Medication, count: Int = 10) {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        // Remove existing notifications for this medication
        cancelNotifications(for: medication)
        
        // Don't schedule for "as needed" medications
        guard let intervalDays = medication.frequency.intervalInDays else {
            return
        }
        
        // Calculate starting date
        let startDate: Date
        if let lastInjection = medication.lastInjectionDate {
            startDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: lastInjection) ?? Date()
        } else {
            // If no injections yet, start tomorrow
            startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
        
        // Schedule multiple notifications in advance
        for i in 0..<count {
            let notificationDate = Calendar.current.date(byAdding: .day, value: intervalDays * i, to: startDate) ?? startDate
            
            // Only schedule future notifications
            guard notificationDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "💉 Injection Reminder"
            content.body = "Time for your \(medication.name) injection (\(medication.dosage))"
            content.sound = .default
            content.badge = 1
            content.userInfo = [
                "medicationId": medication.id.uuidString,
                "medicationName": medication.name,
                "sequence": i
            ]
            
            // Create trigger for the specific date and time (default to 9:00 AM)
            var components = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
            components.hour = 9
            components.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "medication-\(medication.id.uuidString)-\(i)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification \(i) for \(medication.name): \(error)")
                } else {
                    print("Scheduled notification \(i) for \(medication.name) at \(notificationDate)")
                }
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelNotifications(for medication: Medication) {
        // Cancel single notification
        center.removePendingNotificationRequests(withIdentifiers: ["medication-\(medication.id.uuidString)"])
        
        // Cancel recurring notifications (check for sequences 0-9)
        let identifiers = (0..<10).map { "medication-\(medication.id.uuidString)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        
        print("Cancelled notifications for \(medication.name)")
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("Cancelled all notifications")
    }
    
    // MARK: - Notification Response Handling
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        if let medicationIdString = userInfo["medicationId"] as? String,
           let medicationId = UUID(uuidString: medicationIdString) {
            
            // You can add logic here to handle the notification tap
            // For example, open the app to the specific medication
            print("Notification tapped for medication ID: \(medicationId)")
        }
    }
    
    // MARK: - Utility Methods
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    func getNotificationCount(for medication: Medication) async -> Int {
        let pending = await getPendingNotifications()
        return pending.filter { request in
            request.identifier.contains(medication.id.uuidString)
        }.count
    }
}