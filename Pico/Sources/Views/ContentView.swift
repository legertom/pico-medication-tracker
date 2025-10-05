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
                MedicationFormView()
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
    @State private var showingEditSheet = false
    
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
                    
                    HStack(spacing: 8) {
                        Button("Edit") {
                            showingEditSheet = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        
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
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingInjectionSheet) {
            RecordInjectionView(medication: medication)
        }
        .sheet(isPresented: $showingEditSheet) {
            MedicationFormView(medication: medication)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct MedicationFormView: View {
    @EnvironmentObject var medicationStore: MedicationStore
    @Environment(\.dismiss) private var dismiss
    
    // Optional medication for edit mode (nil = add mode)
    let medicationToEdit: Medication?
    
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
    
    init(medication: Medication? = nil) {
        self.medicationToEdit = medication
    }
    
    var isEditMode: Bool {
        medicationToEdit != nil
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
            .navigationTitle(isEditMode ? "Edit Medication" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                populateFieldsFromMedication()
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
                        saveMedication()
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
    
    private func populateFieldsFromMedication() {
        guard let medication = medicationToEdit else { return }
        
        name = medication.name
        dosage = medication.dosage
        selectedSite = medication.injectionSite
        selectedFrequency = medication.frequency
        notes = medication.notes
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
    
    private func saveMedication() {
        if isEditMode {
            // Edit existing medication
            guard let originalMedication = medicationToEdit else { return }
            var updatedMedication = originalMedication
            updatedMedication.name = name
            updatedMedication.dosage = dosage
            updatedMedication.injectionSite = selectedSite
            updatedMedication.frequency = selectedFrequency
            updatedMedication.notes = notes
            medicationStore.updateMedication(updatedMedication)
        } else {
            // Add new medication
            let medication = Medication(
                name: name,
                dosage: dosage,
                injectionSite: selectedSite,
                frequency: selectedFrequency,
                notes: notes
            )
            medicationStore.addMedication(medication)
        }
        dismiss()
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
    @EnvironmentObject var medicationStore: MedicationStore
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.medicationName)
                    .font(.headline)
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDateTime(record.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
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
        .sheet(isPresented: $showingEditSheet) {
            EditInjectionRecordView(record: record)
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EditInjectionRecordView: View {
    let originalRecord: InjectionRecord
    @EnvironmentObject var medicationStore: MedicationStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSite: InjectionSite
    @State private var notes: String
    @State private var selectedDate: Date
    
    init(record: InjectionRecord) {
        print("🔍 EditInjectionRecordView init - Editing record for \(record.medicationName)")
        print("   Site: \(record.injectionSite.displayName)")
        print("   Notes: \(record.notes)")
        print("   Date: \(record.timestamp)")
        
        self.originalRecord = record
        self._selectedSite = State(initialValue: record.injectionSite)
        self._notes = State(initialValue: record.notes)
        self._selectedDate = State(initialValue: record.timestamp)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Injection Details") {
                    HStack {
                        Text("Medication:")
                        Spacer()
                        Text(originalRecord.medicationName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Dosage:")
                        Spacer()
                        Text(originalRecord.dosage)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Injection Site", selection: $selectedSite) {
                        ForEach(InjectionSite.allCases, id: \.self) { site in
                            Text(site.displayName).tag(site)
                        }
                    }
                    
                    DatePicker(
                        "Date & Time",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section("Notes") {
                    TextField("Optional notes about this injection", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Injection ✏️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        saveChanges()
                    }
                    .disabled(selectedDate > Date()) // Prevent future dates
                }
            }
        }
    }
    
    private func saveChanges() {
        print("💾 Saving injection record changes")
        print("   Original site: \(originalRecord.injectionSite.displayName)")
        print("   New site: \(selectedSite.displayName)")
        print("   Original notes: \(originalRecord.notes)")
        print("   New notes: \(notes)")
        
        var updatedRecord = originalRecord
        updatedRecord.injectionSite = selectedSite
        updatedRecord.notes = notes
        updatedRecord.timestamp = selectedDate
        
        print("   Calling updateInjectionRecord...")
        medicationStore.updateInjectionRecord(updatedRecord)
        print("   Dismissing edit view...")
        dismiss()
    }
}

struct SettingsView: View {
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var medicationStore: MedicationStore
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                        Text("Injection Reminders")
                        Spacer()
                        Text(notificationStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if notificationService.authorizationStatus == .denied {
                        Text("Notifications are disabled. Please enable them in Settings to receive injection reminders.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if !notificationService.isAuthorized {
                        Button("Enable Notifications") {
                            Task {
                                await notificationService.requestPermission()
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    if notificationService.isAuthorized {
                        Text("🎯 Notifications are scheduled automatically when you add medications or record injections.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
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
                
                if notificationService.isAuthorized {
                    Section("Debug") {
                        Button("Cancel All Notifications") {
                            notificationService.cancelAllNotifications()
                        }
                        .foregroundColor(.red)
                        
                        Button("Reschedule All Notifications") {
                            for medication in medicationStore.activeMedications {
                                notificationService.scheduleRecurringNotifications(for: medication)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MedicationStore())
}