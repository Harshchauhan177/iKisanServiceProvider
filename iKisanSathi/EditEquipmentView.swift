import SwiftUI

struct EditEquipmentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    let equipment: DataController.Equipment
    
    @State private var name: String
    @State private var type: String
    @State private var capacity: String
    @State private var pricePerHour: Double
    @State private var pricePerAcre: Double
    @State private var location: String
    @State private var modelYear: String
    @State private var mileage: String
    @State private var description: String
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    
    // Validation states
    @State private var nameError: String? = nil
    @State private var capacityError: String? = nil
    @State private var modelYearError: String? = nil
    @State private var mileageError: String? = nil
    
    // Input constraints
    private let maxNameLength = 50
    private let maxCapacityLength = 30
    private let maxDescriptionLength = 500
    private let maxMileageLength = 10
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let minYear = 1980
    
    init(equipment: DataController.Equipment) {
        self.equipment = equipment
        _name = State(initialValue: equipment.name)
        _type = State(initialValue: equipment.type)
        _capacity = State(initialValue: equipment.capacity)
        _pricePerHour = State(initialValue: equipment.pricePerHour)
        _pricePerAcre = State(initialValue: equipment.pricePerAcre)
        _location = State(initialValue: equipment.location)
        _modelYear = State(initialValue: equipment.modelYear)
        _mileage = State(initialValue: equipment.mielage)
        _description = State(initialValue: equipment.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    VStack(alignment: .leading) {
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: name) { newValue in
                                validateName(newValue)
                            }
                        if let error = nameError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 2)
                        }
                    }
                    
                    TextField("Type", text: $type)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    VStack(alignment: .leading) {
                        TextField("Capacity", text: $capacity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: capacity) { newValue in
                                validateCapacity(newValue)
                            }
                        if let error = capacityError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 2)
                        }
                    }
                }
                
                Section(header: Text("Pricing")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("₨")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            TextField("Price per Hour", value: $pricePerHour, format: .number)
                                .keyboardType(.decimalPad)
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Minimum: ₨10, Maximum: ₨10,000")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("₨")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            TextField("Price per Acre", value: $pricePerAcre, format: .number)
                                .keyboardType(.decimalPad)
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Minimum: ₨100, Maximum: ₨50,000")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Details")) {
                    TextField("Location", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    VStack(alignment: .leading) {
                        TextField("Model Year", text: $modelYear)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: modelYear) { newValue in
                                validateModelYear(newValue)
                            }
                        if let error = modelYearError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 2)
                        } else {
                            Text("Enter year between \(minYear) and \(currentYear)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        TextField("Mileage (hours/km)", text: $mileage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: mileage) { newValue in
                                validateMileage(newValue)
                            }
                        if let error = mileageError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 2)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .onChange(of: description) { newValue in
                                if newValue.count > maxDescriptionLength {
                                    description = String(newValue.prefix(maxDescriptionLength))
                                }
                            }
                        HStack {
                            Spacer()
                            Text("\(description.count)/\(maxDescriptionLength)")
                                .font(.caption2)
                                .foregroundColor(description.count > maxDescriptionLength * 9/10 ? .orange : .secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if validateAllFields() {
                            Task {
                                do {
                                    try await dataController.updateEquipment(
                                        id: equipment.equipmentID,
                                        name: name,
                                        type: type,
                                        capacity: capacity,
                                        pricePerHour: pricePerHour,
                                        pricePerAcre: pricePerAcre,
                                        location: location,
                                        modelYear: modelYear,
                                        mileage: mileage,
                                        description: description
                                    )
                                    dismiss()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingErrorAlert = true
                                }
                            }
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Equipment", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await dataController.deleteEquipment(id: equipment.equipmentID)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this equipment? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Validation Functions
    
    private var isFormValid: Bool {
        return nameError == nil && 
               capacityError == nil && 
               modelYearError == nil && 
               mileageError == nil &&
               !name.isEmpty && 
               !capacity.isEmpty && 
               !modelYear.isEmpty &&
               pricePerHour >= 10 && pricePerHour <= 10000 &&
               pricePerAcre >= 100 && pricePerAcre <= 50000
    }
    
    private func validateAllFields() -> Bool {
        validateName(name)
        validateCapacity(capacity)
        validateModelYear(modelYear)
        validateMileage(mileage)
        
        if !isFormValid {
            errorMessage = "Please fix all validation errors before saving"
            showingErrorAlert = true
            return false
        }
        return true
    }
    
    private func validateName(_ name: String) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Equipment name is required"
        } else if name.count > maxNameLength {
            nameError = "Name must be less than \(maxNameLength) characters"
        } else if name.count < 2 {
            nameError = "Name must be at least 2 characters"
        } else {
            nameError = nil
        }
    }
    
    private func validateCapacity(_ capacity: String) {
        if capacity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            capacityError = "Capacity is required"
        } else if capacity.count > maxCapacityLength {
            capacityError = "Capacity must be less than \(maxCapacityLength) characters"
        } else if capacity.count < 2 {
            capacityError = "Capacity must be at least 2 characters"
        } else {
            capacityError = nil
        }
    }
    
    private func validateModelYear(_ yearString: String) {
        if yearString.isEmpty {
            modelYearError = "Model year is required"
            return
        }
        
        guard let year = Int(yearString) else {
            modelYearError = "Please enter a valid year"
            return
        }
        
        if year < minYear {
            modelYearError = "Year cannot be earlier than \(minYear)"
        } else if year > currentYear {
            modelYearError = "Year cannot be later than \(currentYear)"
        } else {
            modelYearError = nil
        }
    }
    
    private func validateMileage(_ mileage: String) {
        if mileage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            mileageError = "Mileage is required"
        } else if mileage.count > maxMileageLength {
            mileageError = "Mileage must be less than \(maxMileageLength) characters"
        } else {
            // Check if mileage contains only valid characters (numbers, decimals, units)
            let allowedCharacters = CharacterSet(charactersIn: "0123456789.,/ kmhrsmiles")
            if mileage.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
                mileageError = "Please enter valid mileage (e.g., 50000 km, 1500 hrs)"
            } else {
                mileageError = nil
            }
        }
    }
}
