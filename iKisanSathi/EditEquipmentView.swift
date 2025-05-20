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
                    TextField("Name", text: $name)
                    TextField("Type", text: $type)
                    TextField("Capacity", text: $capacity)
                }
                
                Section(header: Text("Pricing")) {
                    HStack {
                        Text("₹")
                        TextField("Price per Hour", value: $pricePerHour, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("₹")
                        TextField("Price per Acre", value: $pricePerAcre, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Details")) {
                    TextField("Location", text: $location)
                    TextField("Model Year", text: $modelYear)
                    TextField("Mileage", text: $mileage)
                    TextEditor(text: $description)
                        .frame(height: 100)
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
}
