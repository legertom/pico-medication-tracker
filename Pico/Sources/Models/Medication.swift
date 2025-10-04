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

enum MedicationFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case twiceDaily = "Twice Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case asNeeded = "As Needed"
    
    var displayName: String {
        return self.rawValue
    }
    
    var intervalInDays: Int? {
        switch self {
        case .daily: return 1
        case .twiceDaily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .asNeeded: return nil
        }
    }
}