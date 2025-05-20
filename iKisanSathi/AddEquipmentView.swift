import SwiftUI
import PhotosUI

struct AddEquipmentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var name = ""
    @State private var type = ""
    @State private var capacity = ""
    @State private var availabilityStartDate = Date()
    @State private var availabilityEndDate = Date().addingTimeInterval(30*24*60*60) // 30 days ahead
    @State private var pricePerHour = ""
    @State private var realPricePerHour = ""
    @State private var pricePerAcre = ""
    @State private var realPricePerAcre = ""
    @State private var rating = 5.0
    @State private var location = ""
    @State private var coEquipDetail = coEquipState.Available
    @State private var modelYear = ""
    @State private var mielage = ""
    @State private var description = ""
    @State private var isRecommended = false
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let equipmentTypes = ["Agricultural", "Rice", "Wheat"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Equipment Name", text: $name)
                    
                    Picker("Equipment Type", selection: $type) {
                        Text("Select Type").tag("")
                        ForEach(equipmentTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    VStack {
                        if let selectedImageData,
                           let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                        }
                        
                        PhotosPicker(selection: $selectedItem,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            HStack {
                                Image(systemName: "photo")
                                Text(selectedImageData == nil ? "Select Equipment Photo" : "Change Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                    
                    TextField("Capacity", text: $capacity)
                }
                
                Section(header: Text("Availability & Location")) {
                    DatePicker("Start Date", selection: $availabilityStartDate, displayedComponents: [.date])
                    DatePicker("End Date", selection: $availabilityEndDate, displayedComponents: [.date])
                    TextField("Location", text: $location)
                }
                
                Section(header: Text("Pricing")) {
                    TextField("Price per Hour ($)", text: $pricePerHour)
                        .keyboardType(.decimalPad)
                    TextField("Real Price per Hour ($)", text: $realPricePerHour)
                        .keyboardType(.decimalPad)
                    TextField("Price per Acre ($)", text: $pricePerAcre)
                        .keyboardType(.decimalPad)
                    TextField("Real Price per Acre ($)", text: $realPricePerAcre)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Equipment Details")) {
                    TextField("Model Year", text: $modelYear)
                        .keyboardType(.numberPad)
                    TextField("Mileage", text: $mielage)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Status")) {
                    Picker("Equipment Status", selection: $coEquipDetail) {
                        Text("Available").tag(coEquipState.Available)
                        Text("Unavailable").tag(coEquipState.Unavailable)
                    }
                    Toggle("Recommended Equipment", isOn: $isRecommended)
                }
            }
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEquipment()
                    }
                }
            }
            .alert("Equipment Status", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveEquipment() {
        // Basic Information Validation
        guard !name.isEmpty else {
            alertMessage = "Please enter equipment name"
            showingAlert = true
            return
        }
        
        guard !type.isEmpty else {
            alertMessage = "Please select equipment type"
            showingAlert = true
            return
        }
        
        guard selectedImageData != nil else {
            alertMessage = "Please select an equipment photo"
            showingAlert = true
            return
        }
        
        guard !capacity.isEmpty else {
            alertMessage = "Please specify equipment capacity"
            showingAlert = true
            return
        }
        
        // Date Validation
        guard availabilityStartDate <= availabilityEndDate else {
            alertMessage = "End date must be after start date"
            showingAlert = true
            return
        }
        
        // Price Validation
        guard let priceHour = Double(pricePerHour), priceHour > 0,
              let realPriceHour = Double(realPricePerHour), realPriceHour > 0,
              let priceAcre = Double(pricePerAcre), priceAcre > 0,
              let realPriceAcre = Double(realPricePerAcre), realPriceAcre > 0 else {
            alertMessage = "Please enter valid prices"
            showingAlert = true
            return
        }
        
        // Location Validation
        guard !location.isEmpty else {
            alertMessage = "Please specify equipment location"
            showingAlert = true
            return
        }
        
        // Equipment Details Validation
        guard !modelYear.isEmpty else {
            alertMessage = "Please specify model year"
            showingAlert = true
            return
        }
        
        guard !mielage.isEmpty else {
            alertMessage = "Please specify mileage"
            showingAlert = true
            return
        }
        
        // Save to Supabase
        Task {
            do {
                guard let currentUser = dataController.currentUser else {
                    alertMessage = "User not logged in"
                    showingAlert = true
                    return
                }
                
                // Upload image to Supabase storage and get URL
                guard let imageData = selectedImageData else {
                    alertMessage = "Failed to process image"
                    showingAlert = true
                    return
                }
                
                let imageUrl = try await dataController.uploadEquipmentImage(imageData)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                
                let equipment = DataController.Equipment(
                    equipmentID: UUID(),
                    equipmentImage: imageUrl,
                    name: name,
                    type: type,
                    capacity: capacity,
                    availabilityStartDate: dateFormatter.string(from: availabilityStartDate),
                    availabilityEndDate: dateFormatter.string(from: availabilityEndDate),
                    pricePerHour: Double(pricePerHour) ?? 0.0,
                    realPricePerHour: Double(realPricePerHour) ?? 0.0,
                    pricePerAcre: Double(pricePerAcre) ?? 0.0,
                    realPricePerAcre: Double(realPricePerAcre) ?? 0.0,
                    providerID: currentUser.id,
                    rating: rating,
                    location: location,
                    coEquipDetail: coEquipDetail,
                    modelYear: modelYear,
                    mielage: mielage,
                    description: description,
                    isRecommended: isRecommended,
                    providerName: currentUser.email,
                    preBookingStatus: "")
                
                try await dataController.addEquipment(equipment)
                
                alertMessage = "Equipment added successfully"
                showingAlert = true
                dismiss()
            } catch {
                alertMessage = "Error adding equipment: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}
