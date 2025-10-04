import Foundation
import Combine

class MedicationStore: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var injectionRecords: [InjectionRecord] = []
    
    private let medicationsKey = "PicoMedications"
    private let injectionsKey = "PicoInjections"
    
    init() {
        loadMedications()
        loadInjectionRecords()
    }
    
    // MARK: - Medication Management
    
    func addMedication(_ medication: Medication) {
        medications.append(medication)
        saveMedications()
    }
    
    func updateMedication(_ medication: Medication) {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
            saveMedications()
        }
    }
    
    func deleteMedication(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
        // Also remove associated injection records
        injectionRecords.removeAll { $0.medicationId == medication.id }
        saveMedications()
        saveInjectionRecords()
    }
    
    func toggleMedicationActive(_ medication: Medication) {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index].isActive.toggle()
            saveMedications()
        }
    }
    
    // MARK: - Injection Records Management
    
    func recordInjection(for medication: Medication, site: InjectionSite? = nil, notes: String = "") {
        let injectionSite = site ?? medication.injectionSite
        let record = InjectionRecord(
            medicationId: medication.id,
            medicationName: medication.name,
            dosage: medication.dosage,
            injectionSite: injectionSite,
            notes: notes
        )
        
        injectionRecords.append(record)
        
        // Update last injection date for the medication
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index].lastInjectionDate = record.timestamp
            saveMedications()
        }
        
        saveInjectionRecords()
    }
    
    func getInjectionRecords(for medication: Medication) -> [InjectionRecord] {
        return injectionRecords
            .filter { $0.medicationId == medication.id }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    func deleteInjectionRecord(_ record: InjectionRecord) {
        injectionRecords.removeAll { $0.id == record.id }
        saveInjectionRecords()
    }
    
    // MARK: - Persistence
    
    private func saveMedications() {
        if let encoded = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(encoded, forKey: medicationsKey)
        }
    }
    
    private func loadMedications() {
        if let data = UserDefaults.standard.data(forKey: medicationsKey),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            medications = decoded
        }
    }
    
    private func saveInjectionRecords() {
        if let encoded = try? JSONEncoder().encode(injectionRecords) {
            UserDefaults.standard.set(encoded, forKey: injectionsKey)
        }
    }
    
    private func loadInjectionRecords() {
        if let data = UserDefaults.standard.data(forKey: injectionsKey),
           let decoded = try? JSONDecoder().decode([InjectionRecord].self, from: data) {
            injectionRecords = decoded
        }
    }
    
    // MARK: - Convenience Methods
    
    var activeMedications: [Medication] {
        medications.filter { $0.isActive }
    }
    
    var inactiveMedications: [Medication] {
        medications.filter { !$0.isActive }
    }
    
    func nextDueDate(for medication: Medication) -> Date? {
        guard let lastInjection = medication.lastInjectionDate,
              let intervalDays = medication.frequency.intervalInDays else {
            return nil
        }
        
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: lastInjection)
    }
    
    func isOverdue(medication: Medication) -> Bool {
        guard let nextDue = nextDueDate(for: medication) else {
            return false
        }
        
        return Date() > nextDue
    }
}

struct InjectionRecord: Identifiable, Codable {
    let id = UUID()
    let medicationId: UUID
    let medicationName: String
    let dosage: String
    let injectionSite: InjectionSite
    let timestamp: Date
    let notes: String
    
    init(medicationId: UUID, medicationName: String, dosage: String, injectionSite: InjectionSite, notes: String = "") {
        self.medicationId = medicationId
        self.medicationName = medicationName
        self.dosage = dosage
        self.injectionSite = injectionSite
        self.timestamp = Date()
        self.notes = notes
    }
}