import SwiftUI

@main
struct PicoApp: App {
    @StateObject private var medicationStore = MedicationStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(medicationStore)
        }
    }
}