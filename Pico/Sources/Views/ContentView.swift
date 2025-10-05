import SwiftUI

struct ContentView: View {
    @EnvironmentObject var medicationStore: MedicationStore
    @State private var selectedTab = 0
    @State private var showingAddMedication = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MedicationListView()
                .tabItem {
                    Image(systemName: "pills.fill")
                    Text("Medications")
                }
                .tag(0)
            
            InjectionHistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

struct MedicationListView: View {
    @EnvironmentObject var medicationStore: MedicationStore
    @State private var showingAddMedication = false
    
    var body: some View {
        NavigationView {
            List {
                if medicationStore.activeMedications.isEmpty {
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "pills")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No medications yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Tap + to add your first medication")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(medicationStore.activeMedications) { medication in
                        MedicationRowView(medication: medication)
                    }
                    .onDelete(perform: deleteMedications)
                }
            }
            .navigationTitle("Pico")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMedication = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView()
            }
        }
    }
    
    private func deleteMedications(offsets: IndexSet) {
        for index in offsets {
            medicationStore.deleteMedication(medicationStore.activeMedications[index])
        }
    }
}

struct MedicationRowView: View {
    let medication: Medication
    @EnvironmentObject var medicationStore: MedicationStore
    @State private var showingInjectionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.headline)
                    
                    Text("\(medication.dosage) • \(medication.injectionSite.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(medication.frequency.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let lastInjection = medication.lastInjectionDate {
                        Text("Last: \(formatDate(lastInjection))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if medicationStore.isOverdue(medication: medication) {
                            Text("OVERDUE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        } else if let nextDue = medicationStore.nextDueDate(for: medication) {
                            Text("Next: \(formatDate(nextDue))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("No injections yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Record Injection") {
                        showingInjectionSheet = true
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingInjectionSheet) {
            RecordInjectionView(medication: medication)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct AddMedicationView: View {
    @EnvironmentObject var medicationStore: MedicationStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var selectedSite = InjectionSite.subcutaneous
    @State private var selectedFrequency = MedicationFrequency.daily
    @State private var notes = ""
    @State private var showingCustomFrequency = false
    @State private var customDays = 1
    @State private var customWeeks = 1
    @State private var customType: CustomFrequencyType = .days
    
    enum CustomFrequencyType: String, CaseIterable {
        case days = "Days"
        case weeks = "Weeks"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Medication Details") {
                    TextField("Name", text: $name)
                    TextField("Dosage (e.g., 0.5ml, 25mg)", text: $dosage)
                    
                    Picker("Injection Site", selection: $selectedSite) {
                        ForEach(InjectionSite.allCases, id: \.self) { site in
                            Text(site.displayName).tag(site)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Frequency")
                            .font(.headline)
                        
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(MedicationFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                            Text("Custom").tag(MedicationFrequency.customDays(1))
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedFrequency) { _, newValue in
                            if newValue.isCustom {
                                showingCustomFrequency = true
                            } else {
                                showingCustomFrequency = false
                            }
                        }
                        
                        if showingCustomFrequency || selectedFrequency.isCustom {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Custom Interval")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("Every")
                                    
                                    Picker("Interval", selection: $customType) {
                                        ForEach(CustomFrequencyType.allCases, id: \.self) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                                
                                HStack {
                                    if customType == .days {
                                        Stepper("\(customDays) day\(customDays == 1 ? "" : "s")", value: $customDays, in: 1...365)
                                    } else {
                                        Stepper("\(customWeeks) week\(customWeeks == 1 ? "" : "s")", value: $customWeeks, in: 1...52)
                                    }
                                }
                                .onChange(of: customDays) { _, newValue in
                                    if customType == .days {
                                        selectedFrequency = .customDays(newValue)
                                    }
                                }
                                .onChange(of: customWeeks) { _, newValue in
                                    if customType == .weeks {
                                        selectedFrequency = .customWeeks(newValue)
                                    }
                                }
                                .onChange(of: customType) { _, newValue in
                                    switch newValue {
                                    case .days:
                                        selectedFrequency = .customDays(customDays)
                                    case .weeks:
                                        selectedFrequency = .customWeeks(customWeeks)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                initializeCustomFrequency()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let medication = Medication(
                            name: name,
                            dosage: dosage,
                            injectionSite: selectedSite,
                            frequency: selectedFrequency,
                            notes: notes
                        )
                        medicationStore.addMedication(medication)
                        dismiss()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
    
    private func initializeCustomFrequency() {
        switch selectedFrequency {
        case .customDays(let days):
            customDays = days
            customType = .days
            showingCustomFrequency = true
        case .customWeeks(let weeks):
            customWeeks = weeks
            customType = .weeks
            showingCustomFrequency = true
        default:
            showingCustomFrequency = false
        }
    }
}

struct RecordInjectionView: View {
    let medication: Medication
    @EnvironmentObject var medicationStore: MedicationStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSite: InjectionSite
    @State private var notes = ""
    
    init(medication: Medication) {
        self.medication = medication
        self._selectedSite = State(initialValue: medication.injectionSite)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Injection Details") {
                    Text("Medication: \(medication.name)")
                    Text("Dosage: \(medication.dosage)")
                    
                    Picker("Injection Site", selection: $selectedSite) {
                        ForEach(InjectionSite.allCases, id: \.self) { site in
                            Text(site.displayName).tag(site)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes about this injection", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Record Injection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Record") {
                        medicationStore.recordInjection(
                            for: medication,
                            site: selectedSite,
                            notes: notes
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InjectionHistoryView: View {
    @EnvironmentObject var medicationStore: MedicationStore
    
    var body: some View {
        NavigationView {
            List {
                if medicationStore.injectionRecords.isEmpty {
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No injection history")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Record your first injection to see history here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(medicationStore.injectionRecords.sorted { $0.timestamp > $1.timestamp }) { record in
                        InjectionRecordRow(record: record)
                    }
                    .onDelete(perform: deleteRecords)
                }
            }
            .navigationTitle("Injection History")
        }
    }
    
    private func deleteRecords(offsets: IndexSet) {
        let sortedRecords = medicationStore.injectionRecords.sorted { $0.timestamp > $1.timestamp }
        for index in offsets {
            medicationStore.deleteInjectionRecord(sortedRecords[index])
        }
    }
}

struct InjectionRecordRow: View {
    let record: InjectionRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.medicationName)
                    .font(.headline)
                Spacer()
                Text(formatDateTime(record.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("\(record.dosage) • \(record.injectionSite.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
                
                Section("Support") {
                    Link("Contact Support", destination: URL(string: "mailto:support@pico.app")!)
                    Link("Report a Bug", destination: URL(string: "https://example.com/bug-report")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MedicationStore())
}