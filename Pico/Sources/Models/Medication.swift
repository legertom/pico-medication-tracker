import Foundation

struct Medication: Identifiable, Codable {
    let id = UUID()
    var name: String
    var dosage: String
    var injectionSite: InjectionSite
    var frequency: MedicationFrequency
    var notes: String
    var isActive: Bool
    var createdDate: Date
    var lastInjectionDate: Date?
    
    init(
        name: String,
        dosage: String,
        injectionSite: InjectionSite = .subcutaneous,
        frequency: MedicationFrequency = .daily,
        notes: String = "",
        isActive: Bool = true
    ) {
        self.name = name
        self.dosage = dosage
        self.injectionSite = injectionSite
        self.frequency = frequency
        self.notes = notes
        self.isActive = isActive
        self.createdDate = Date()
        self.lastInjectionDate = nil
    }
}

enum InjectionSite: String, CaseIterable, Codable {
    case subcutaneous = "Subcutaneous"
    case intramuscular = "Intramuscular"
    case intravenous = "Intravenous"
    case intradermal = "Intradermal"
    
    var displayName: String {
        return self.rawValue
    }
}

enum MedicationFrequency: Codable, Hashable {
    case daily
    case twiceDaily
    case weekly
    case biweekly
    case monthly
    case asNeeded
    case customDays(Int)
    case customWeeks(Int)
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .twiceDaily: return "Twice Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .asNeeded: return "As Needed"
        case .customDays(let days): return "Every \(days) day\(days == 1 ? "" : "s")"
        case .customWeeks(let weeks): return "Every \(weeks) week\(weeks == 1 ? "" : "s")"
        }
    }
    
    var intervalInDays: Int? {
        switch self {
        case .daily: return 1
        case .twiceDaily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .asNeeded: return nil
        case .customDays(let days): return days
        case .customWeeks(let weeks): return weeks * 7
        }
    }
    
    // Predefined options for the picker
    static let predefinedCases: [MedicationFrequency] = [
        .daily, .twiceDaily, .weekly, .biweekly, .monthly, .asNeeded
    ]
    
    // Helper to check if this is a custom frequency
    var isCustom: Bool {
        switch self {
        case .customDays, .customWeeks:
            return true
        default:
            return false
        }
    }
    
    // For backward compatibility with CaseIterable functionality
    static var allCases: [MedicationFrequency] {
        return predefinedCases
    }
}
